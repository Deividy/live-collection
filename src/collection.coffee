@liveCollection = (options) -> new LiveCollection(options)

# Events are
#
# add = (obj, index) ->
# update = (obj, index) ->
# remove = (obj, index) ->
# reset = (items, count) ->
# count = (count) ->
#
# model:change = (attribute, value, model) ->
#
# workflowVersion:change = (workflowVersion) ->
#
# save:start = (updates) ->
# save:done = (workflowVersion) ->
# create:done = (data, workflowVersion) ->   
# delete:start = (model) ->
# delete:done = (workflowVersion) ->   
# refresh:done = (data, workflowVersion) ->   
#
# for sync have to implemenet .doSave(), .doDelete(), .doCreate(), .doRefresh()
# doRefresh: (workflowVersion, next) ->
#  next is @finishRefresh(arrayOfItems, workflowVersion)
#
# doCreate: (next) -> 
#  next is @finishCreate(item, workflowVersion)
#
# doDelete: (model, next) ->
#  next is @finishDelete(item, workflowVersion)
#
# doSave: (updates, next) -> 
#  next is @finishSave(itemsById, workflowVersion)

demandLiveModel = (item) ->
    unless item.isLiveModel
        throw new Error("Not a valid item")

class LiveCollection
    constructor: (options = {}, @crud) ->
        _.extend(@, options)
        _.extend(@, Backbone.Events)

        @canRefresh = options.doRefresh?
        @canCreate = options.doCreate?
        @canDelete = options.doDelete?
        @canSave = options.doSave?

        @workflowVersion ?= 0

        @items = [ ]
        @byId = { }

        @queueById = { }
        @lastUpdates = [ ]
        @isRunning = false

        @debounceSave = _.debounce(@save, 100)

        @reset(options.items, options.preSorted) if options.items?
 
    comparator: (a, b) -> 0
    belongs: (o) -> true
    isFresher: (candidate, current) -> true

    doRefresh: (workflowVersion, next) -> throw new Error("Not Implemented")
    doCreate: (next) -> throw new Error("Not Implemented")
    doDelete: (model, next) -> throw new Error("Not Implemented")
    doSave: (updates, next) -> throw new Error("Not Implemented")
    
    # CRUD methods for sync
    refresh: (@workflowVersion) ->
        F.demandFunction(@doRefresh, 'doRefresh')
        @doRefresh(@workflowVersion, _.bind(@finishRefresh, @))

    create: () ->
        F.demandFunction(@doCreate, 'doCreate')

        @doCreate(_.bind(@finishCreate, @))

    delete: (id) ->
        F.demandGoodNumber(id, 'id')
        F.demandFunction(@doDelete, 'doDelete')

        item = @get({ id })
        
        @trigger('delete:start', item)
        @doDelete(item, _.bind(@finishDelete, @))
 
    save: () ->
        F.demandFunction(@doSave, 'doSave')

        return if (_.isEmpty(@queueById) || @isRunning)

        @lastUpdates = [ ]
        for item in _.values(@queueById)
            continue unless item.isDirty()

            changes = item.changes()
            changes.id = item.id
            @lastUpdates.push(changes)

        @queueById = { }

        return if (_.isEmpty(@lastUpdates))

        @isRunning = true

        @trigger("save:start", @lastUpdates)
        @doSave(@lastUpdates, _.bind(@finishSave, @))

    # Finish CRUD for sync
    finishRefresh: (items, workflowVersion) ->
        F.demandGoodArray(items, 'items')
        # MUST:
        # applyValues, check for delete and new items

        @merge(items)

        @nextWorkflowVersion(workflowVersion)
        @trigger('refresh:done', items, @workflowVersion)

    finishCreate: (item, workflowVersion) ->
        F.demandGoodObject(item, 'item')
        @merge(item)

        @nextWorkflowVersion(workflowVersion)
        @trigger('create:done', item, @workflowVersion)

    finishDelete: (item, workflowVersion) ->
        demandLiveModel(item)

        @remove(item)

        @nextWorkflowVersion(workflowVersion)
        @trigger('delete:done', workflowVersion)

    finishSave: (itemsById, workflowVersion) ->
        F.demandGoodObject(itemsById, 'itemsById')
        F.demandGoodNumber(workflowVersion, 'workflowVersion')

        _.each(@lastUpdates, (changes) =>
            item = @byId[changes.id]
            responseItem = itemsById[changes.id]

            _.extend(item.previousValues, changes.newValues)
            responseItem.id = changes.id

            @merge(responseItem)
        )

        @isRunning = false

        @nextWorkflowVersion(workflowVersion)
        @trigger("save:done", @workflowVersion)

        @debounceSave()
    
    # # #
    queue: (item) ->
        F.demandGoodObject(item, 'item')
        demandLiveModel(item)

        @queueById[item.id] = item

        @debounceSave() if (@canSave)

    nextWorkflowVersion: (workflowVersion) ->
        @workflowVersion++
        @trigger("workflowVersion:change", @workflowVersion)

        if workflowVersion?
            return @checkWorkflowVersion(workflowVersion)

        return true

    checkWorkflowVersion: (workflowVersion) ->
        F.demandGoodNumber(workflowVersion, 'workflowVersion')

        if (workflowVersion > @workflowVersion)
            return @refresh(workflowVersion)

        return true
    
    _preAdd: (obj) ->
        F.demandGoodObject(obj, 'obj')

        unless obj.isLiveModel
            return liveModel(obj, @)

        return obj if (obj.liveCollection == @)

        return liveModel(_.pick(obj, obj.attributes), @)

    _compare: (a, b) -> @comparator.call(@, a, b) || @comparePrimitive(a.id, b.id)

    # handles dates, strings, booleans, numbers
    comparePrimitive: (a, b) ->
        # MUST: think about locale and/or removing diacritics
        # as is, accents get pushed to the bottom
        # simply using string.localeCompare() doesn't cut it either
        if _.isString(a) && _.isString(b)
            a = a.toLowerCase()
            b = b.toLowerCase()

        return 0 if a.valueOf() == b.valueOf()
        return if a < b then -1 else 1

    # CRUD front-end reset/merge/remove from items
    reset: (items) ->
        unless _.isArray(items)
            throw new Error('items must be an array')

        @items = []
        @byId = {}
        for o in items
            continue unless @belongs(o)
            o = @_preAdd(o)
            @byId[o.id] = o
            @items.push(o)

        c = _.bind(@comparator, @)
        @items.sort(c)

        @trigger("reset", @items, @items.length)
        @trigger("count", @items.length)
        return @

    merge: (data) ->
        if _.isArray(data)
            @_mergeOne(obj) for obj in data
        else if _.isObject(data)
            @_mergeOne(data)
        else
            throw new Error('Data must be either an array or an object')

        return @

    remove: (e, index) ->
        obj = @tryGet(e)
        return unless obj?

        index ?= @binarySearch(obj)
        delete @byId[obj.id]
        @items.splice(index, 1)
        
        @trigger("remove", obj, index)
        @trigger("count", @items.length)

        obj.destroy()

        return @

    # Search and get methods
    get: (e) ->
        obj = @tryGet(e)
        return obj if obj?

        throw new Error("Did not find object or id #{JSON.stringify(e)}")

    tryGet: (e) ->
        id = e.id ? e
        return @byId[id]

    indexOf: (e) ->
        obj = @get(e)
        return @binarySearch(obj)

    # if the object exists, we find its index. otherwise, we find the index
    # where it should be inserted
    binarySearch: (obj) ->
        return 0 if @items.length == 0

        left = 0
        right = @items.length - 1

        while left <= right
            mid = (left + right) >> 1
            cmp = @_compare(obj, @items[mid])

            left = mid + 1 if (cmp > 0)
            right = mid - 1 if (cmp < 0)
            return mid if cmp == 0

        return if cmp > 0 then mid + 1 else mid
        
    hasRightIndex: (obj, idx) ->
        if idx > 0
            return false if @_compare(@items[idx-1], obj) >= 0

        if idx < @items.length - 1
            return false if @_compare(obj, @items[idx+1]) >= 0

        return true

    # Privates
    _mergeOne: (o) ->
        unless o.id?
            throw new Error("id must not be nil")

        current = @byId[o.id]
        if current?
            return @_update(o, current)
        else
            return unless @belongs(o)
            o = @_preAdd(o)

            @byId[o.id] = o
            idx = @binarySearch(o)
            @items.splice(idx, 0, o)
            @trigger("add", o, idx)
            @trigger("count", @items.length)

    _update: (fresh, current) ->
        return unless @isFresher(fresh, current)
       
        # so we have fresh data. we'll update the object in place. that's
        # dangerous business because the update could change the object's
        # sort order, so before we do anything, let's find the current
        # index.
        idxCurrent = @binarySearch(current)

        updated = false
        for attr in current.attributes
            continue if current[attr] == fresh[attr]
            updated = true
            current.setValue(attr, fresh[attr])

        return unless updated

        # it's possible the object no longer belongs here after the update
        return @remove(current, idxCurrent) unless @belongs(current)

        if @hasRightIndex(current, idxCurrent)
            @trigger("update", current, idxCurrent)
        else
            # since the sort index changed, we'll handle this as remove/add
            # this makes it easy for UIs to fix themselves with the minimum
            # number of operations
            @remove(current, idxCurrent)
            @merge(current)

@liveCollection.Class = LiveCollection
