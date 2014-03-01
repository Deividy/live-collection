liveWrapper = @lineWrapper = ($container, attributes) ->
    return new LiveWrapper($container, attributes)

numberKeyCodes = [
    188, 190, 8, 9, 46, 48, 49, 50, 51, 52, 53, 54, 55, 56,
    57, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 110
]

class LiveWrapper
    constructor: (@$, @attributes, @attributeConfig = { }) ->
        F.demandSelector(@$, "$")
        F.demandArrayOfGoodStrings(@attributes, 'attributes')

        @fields = { }
        @textFields = { }

        for attribute in @attributes
            $field = @$.find("[name='#{attribute}']")
            $textField = @$.find(".#{attribute}")
            
            if ($field.length > 0)
                @fields[attribute] = $field
                continue

            if ($textField.length > 0)
                @textFields[attribute] = $textField

        @bindEvents()

    bindEvents: () ->
        for name, $field of @fields
            $field.on("keydown", @onFieldKeyDown)
            $field.on('focus', @onFieldFocus)
            
        return

    onFieldFocus: (ev) ->
        $el = $(ev.currentTarget)
        if (ev.currentTarget.name in @attributeConfig.numbers)
            $el.val("") if (Number($el.val()) == 0)

    onFieldKeyDown: (ev) ->
        F.demandGoodNumber(ev.keyCode, 'ev.keyCode')
        F.demandFunction(ev.preventDefault, 'ev.preventDefault')

        if (ev.currentTarget.name in @attributeConfig.numbers)
            if (ev.keyCode not in numberKeyCodes)
                return ev.preventDefault()

    populate: (values) ->
        for key, value of values
            @fields[key].val(value) if (@fields[key]?)
            @textFields[key].html(value) if (@textFields[key]?)

        return

    destroy: () ->
        @$.remove()

liveWrapper.Class = LiveWrapper
