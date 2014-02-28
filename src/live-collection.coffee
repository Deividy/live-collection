jsRoot = @

liveCollection = (options) -> new LiveCollection(options)

if module?.exports?
    module.exports = liveCollection
    _ = require('underscore')
    Backbone = require('backbone')
    LiveModel = require('./live-model')
else
    jsRoot.liveCollection = liveCollection
    { Backbone, _, LiveModel } = jsRoot


# Events are
#
# add: (obj, index) ->
# update: (obj, index) ->
# remove: (obj, index) ->
# reset: (items, count) ->
# count: (count) ->

class LiveCollection
    constructor: (options = {}) ->
        _.extend(@, options)
        _.extend(@, Backbone.Events)

        @items = []
        @sorted = @sortFn?
        @byId = {}
        @cloneBeforeAdd ?= true
        @workflowVersion ?= 0

        @reset(options.items, options.preSorted) if options.items?

        @queueById = { }
        @lastSave = [ ]
        @isRunning = false

        @debounceSave = _.debounce(@save, 100)

    doSave: (updates, callback) -> throw new Error("")
    doDelete: (item, callback) -> throw new Error("")
    doAdd: (callback) -> throw new Error("")

    save: () ->
        return if (_.isEmpty(@queueById) || @isRunning)

        @lastSave = [ ]
        for item in _.values(@queueById)
            continue unless item.isDirty()

            changes = item.changes()
            changes.id = item.id
            @lastSave.push(changes)

        @queueById = { }
        return if (_.isEmpty(update))

        @isRunning = true

        @doSave(updates, _.bind(@finishSave, @))

    finishSave: (itemsById) ->
        _.each(@lastSave, (changes) =>
            item = @byId[changes.id]
            responseItem = itemsById[changes.id]

            _.extend(item.previousValues, changes.newValues)

            @applyDbValues(changes.id, responseItem)
        )

        @isRunning = false

        @workflowVersion++
        @trigger("change:workflowVersion", @workflowVersion)

        @checkWorkflowVersion(data.workflowVersion)

        @trigger("save:done", @workflowVersion)
        @debounceSave()

    comparator: (a, b) -> 0
    belongs: (o) -> true
    isFresher: (candidate, current) -> true

    _preAdd: (obj) ->
        if (@cloneBeforeAdd == true)
            obj = _.clone(obj)

        return new LiveModel(obj, @)

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
        for k, v of fresh
            continue if current[k] == v
            updated = true
            current[k] = v

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

    indexOf: (e) ->
        obj = @get(e)
        return @binarySearch(obj)

    get: (e) ->
        obj = @tryGet(e)
        return obj if obj?

        throw new Error("Did not find object or id #{JSON.stringify(e)}")

    tryGet: (e) ->
        id = e.id ? e
        return @byId[id]

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

    remove: (e, index) ->
        obj = @tryGet(e)
        return unless obj?

        index ?= @binarySearch(obj)
        delete @byId[obj.id]
        @items.splice(index, 1)
        @trigger("remove", obj, index)
        @trigger("count", @items.length)

        return @

liveCollection.Class = LiveCollection
