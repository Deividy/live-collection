jsRoot = @

liveModel = (data, collection) -> new LiveModel(data, collection)

if module?.exports?
    module.exports = liveModel
    _ = require('underscore')
    Backbone = require('backbone')
    F = require('functoids')
else
    jsRoot.liveModel = liveModel
    { Backbone, _, F } = jsRoot

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

        lineWrapper.populate(values) for lineWrapper in @lineWrappers

    destroy: () ->
        lineWrapper.destroy() for lineWrapper in @lineWrappers
        delete @

    $: () ->
        $dom = $()
        return $dom if (@lineWrappers.length == 0)

        $dom = $dom.add(lineWrapper.$) for lineWrapper in @lineWrappers

        return $dom