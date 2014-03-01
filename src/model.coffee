@liveModel = (data, collection) -> new LiveModel(data, collection)

class LiveModel
    constructor: (@originalData, @liveCollection) ->
        F.demandGoodObject(@originalData, 'originalData')
        F.demandGoodNumber(@originalData.id, 'originalData.id')
        F.demandGoodObject(@liveCollection, 'liveCollection')

        @attributes = @liveCollection.attributes ? _.keys(@originalData)
        @attributeConfig = @liveCollection.attributeConfig ? { }

        _.extend(@, _.pick(@originalData, @attributes))

        @previousValues = { }
        @liveWrappers = [ ]

        @refresh()

        @isLiveModel = true

    refresh: () -> @previousValues = _.pick(@, @attributes)

    initWrappers: (@lastSelector) ->
        F.demandGoodString(@lastSelector, 'lastSelector')

        @resetWrappers()

        @wrap($(container)) for container in $(@lastSelector)
        return

    wrap: ($container) ->
        #F.demandSelector($container, '$container')

        lw = liveWrapper($container, @attributes)

        @liveWrappers.push(lw)

        #@bindEvents(lw)
        #@forcePopulate(lw)
        
        return lw

    resetWrappers: () ->
        @liveWrappers = [ ]

    findWrapper: ($container) ->
        #F.demandSelector($container, '$container')
        
        $containers = @$()
        for wrapper in @liveWrappers
            if ($containers.index(wrapper.$) == $containers.index($container))
                return wrapper

        throw new Error("Wrapper not found for #{$container}")

    isDirty: () ->
        return (@dirtyAttributes().length > 0)

    dirtyAttributes: () ->
        dirtyAttributes = [ ]

        for attr in @attributes
            if (@[attr] != @previousValues[attr])
                dirtyAttributes.push(attr)

        return dirtyAttributes

    changes: () ->
        dirtyAttributes = @dirtyAttributes()

        changes = {
            @id,
            newValues: _.pick(@, dirtyAttributes),
            previousValues: _.pick(@previousValues, dirtyAttributes)
        }

        # sanitize values before send, just to be safety, safety 1st!
        for key, val in changes.newValues
            pv = changes.previousValues[key]

            changes.newValues[key] = @sanitizeValue(key, val)
            changes.previousValues[key] = @sanitizeValue(key, pv)

        return changes

    sanitizeValue: (attribute, value) ->
        F.demandGoodString(attribute, 'attribute')
        # TODO:
        return value

    setValue: (attribute, val) ->
        F.demandGoodString(attribute, 'attribute')
        val = @sanitizeValue(attribute, val)

        hasChanged = (@[attribute] != val)

        @[attribute] = val

        if (hasChanged)
            @liveCollection.trigger("model:change", attribute, val, @)

    setValues: (values) ->
        F.demandGoodObject(values, 'values')
        @setValue(key, val) for key, val of values

    applyChanges: () ->
        values = { }

        for attr in @attributes
            if (@[attr] != @previousValues[attr])
                values[attr] = @[attr]

        return if (_.isEmpty(values))

        lw.populate(values) for lw in @liveWrappers

    destroy: () ->
        lw.destroy() for lw in @liveWrappers
        delete @

    $: () ->
        $dom = $()
        return $dom if (@liveWrappers.length == 0)

        $dom = $dom.add(lw.$) for lw in @liveWrappers

        return $dom


@liveModel.Class = LiveModel
