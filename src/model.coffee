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

    ## Wrappers
    initWrappers: (@lastSelector) ->
        F.demandGoodString(@lastSelector, 'lastSelector')

        @resetWrappers()

        @wrap($(container)) for container in $(@lastSelector)
        return

    wrap: ($container) ->
        #F.demandSelector($container, '$container')

        lw = liveWrapper($container, @attributes)

        @liveWrappers.push(lw)

        @bindEvents(lw)
        @forcePopulate(lw)
        
        return lw

    resetWrappers: () ->
        @liveWrappers = [ ]

    getWrapper: ($container) ->
        #F.demandSelector($container, '$container')
        
        $containers = @$()
        for lw in @liveWrappers
            if ($containers.index(lw.$) == $containers.index($container))
                return lw

        throw new Error("Wrapper not found for #{$container}")

    forcePopulate: (lw) ->
        F.demandGoodObject(lw, 'lw')
        lw.populate(_.pick(@, @attributes))

    forcePopulateAll: () ->
        values = _.pick(@, @attributes)
        lw.populate(values) for lw in @liveWrappers

    $: () ->
        $dom = $()
        return $dom if (@liveWrappers.length == 0)

        $dom = $dom.add(lw.$) for lw in @liveWrappers

        return $dom
 
    ## Events
    bindEvents: (lw) ->
        F.demandGoodObject(lw, 'lw')

        for name, field of lw.fields
            field.on("keyup", _.bind(@onFieldKeyUp, @))
            field.on("change", _.bind(@onFieldChange, @))

        return

    onFieldKeyUp: (ev) ->
        @setValue(ev.currentTarget.name, $(ev.currentTarget).val())
        
    onFieldChange: (ev) ->
        F.demandFunction(ev.preventDefault, 'ev.preventDefault')
        ev.preventDefault()

        $item = $(ev.currentTarget).closest("[data-rowid]")

        name = ev.currentTarget.name
        val = $(ev.currentTarget).val()

        @setValue(name, val)

    ## Setters
    setValue: (attribute, val) ->
        F.demandGoodString(attribute, 'attribute')
        val = @sanitizeValue(attribute, val)

        hasChanged = (@[attribute] != val)

        @[attribute] = val

        if (hasChanged)
            @liveCollection.trigger("model:change", attribute, val, @)
        
        @setValueInWrappers(attribute, val)

    setValues: (values) ->
        F.demandGoodObject(values, 'values')
        @setValue(key, val) for key, val of values

    setValueInWrappers: (attribute, value) ->
        for lw in @liveWrappers
            if (lw.fields[attribute])
                lw.fields[attribute].val(value)
                continue

            if (lw.textFields[attribute])
                lw.textFields[attribute].html(value)

        return

    sanitizeValue: (attribute, value) ->
        F.demandGoodString(attribute, 'attribute')
        # TODO:
        return value

    applyChanges: () ->
        values = { }

        for attr in @attributes
            if (@[attr] != @previousValues[attr])
                values[attr] = @[attr]

        return if (_.isEmpty(values))

        lw.populate(values) for lw in @liveWrappers

    ## Dirty / Change
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

    destroy: () ->
        lw.destroy() for lw in @liveWrappers
        delete @

@liveModel.Class = LiveModel
