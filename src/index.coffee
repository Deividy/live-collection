jsRoot = @

liveCollection = (options) -> new LiveCollection(options)

if module?.exports?
    module.exports = liveCollection
    _ = require('underscore')
else
    jsRoot.liveCollection = liveCollection
    _ = jsRoot._

liveCollection.Class = LiveCollection

class LiveCollection
    constructor: (options = {}) ->
        _.extend(@, options)
        @items = []
        @sorted = @sortFn?
        @byId = {}
        @cloneBeforeAdd ?= true

        @_preAdd = if @cloneBeforeAdd == false then _.identity else _.clone
        @reset(options.items, options.preSorted) if options.items?

    comparator: (a, b) -> 0
    belongs: (o) -> true
    isFresher: (candidate, current) -> true

    _compare: (a, b) -> @comparator.call(@, a, b) || @comparePrimitive(a.id, b.id)

    comparePrimitive: (a, b) ->
        # MUST: think about locale and/or removing diacritics
        # as is, accents get pushed to the bottom
        # simply using string.localeCompare() doesn't cut it either
        if _.isString(a) && _.isString(b)
            a = a.toLowerCase()
            b = b.toLowerCase()

        return 0 if a == b
        return if a < b then -1 else 1

    reset: (items) ->
        unless _.isArray(items)
            throw new Error('items must be an array')

        @items = []
        for o in items
            continue unless @belongs(o)
            @byId[o.id] = o
            @items.push(@_preAdd(o))

        c = _.bind(@comparator, @)
        @items.sort(c)

        @onReset(@items, @items.length)
        return @

    merge: (data) ->
        if _.isArray(data)
            @_mergeOne(obj) for obj in data
        else if _.isObject(data)
            @_mergeOne(data)
        else
            throw new Exception('Data must be either an array or an object')

        return @

    _mergeOne: (o) ->
        current = @byId[o.id]
        if current?
            return @_update(o, current)
        else
            return unless @belongs(o)
            o = @_preAdd(o)

            @byId[o.id] = o
            idx = @binarySearch(o)
            @items.splice(idx, 0, o)
            @onAdd(o, idx)
            @onCount(@items.length)

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
            @onUpdate(current, idxCurrent)
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
        @onRemove(obj, index)
        @onCount(@items.length)

        return @

    onAdd: (obj, index) ->
    onUpdate: (obj, index) ->
    onRemove: (obj, index) ->
    onReset: (items, count) ->
    onCount: (count) ->
