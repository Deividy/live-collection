{ liveWrapper, $ } = @

attributes = [ 'firstName', 'lastName', 'age' ]
attributeConfig = { numbers: [ 'age' ] }

lw = $container = null

describe 'LiveWrapper', () ->
    beforeEach () ->
        document.body.innerHTML = __html__['specs/wrapper.html']

        $container = $(".user[data-rowid='1']")
        lw = liveWrapper($container, attributes, attributeConfig)

    it 'should set values in dom by wrapper.fields', () ->
        lw.fields.firstName.val('Deividy')
        lw.fields.lastName.val('Metheler')
        lw.fields.age.val('10')

        $container
            .find("input[name='firstName']").val()
            .should.eql(lw.fields.firstName.val())

        $container
            .find("input[name='lastName']").val()
            .should.eql(lw.fields.lastName.val())

        $container
            .find("input[name='age']").val()
            .should.eql(lw.fields.age.val())

    it 'should test events', (done) ->
        lw.fields.age.val('0').triggerHandler('focus')
        
        $container
            .find("input[name='age']").val()
            .should.eql("")

        lw.onFieldKeyDown({
            keyCode: 188,
            currentTarget: {
                name: 'age'
            },
            preventDefault: () -> throw Error('Should not be called!'),
        })

        lw.onFieldKeyDown({
            keyCode: 22,
            currentTarget: {
                name: 'lastName'
            },
            preventDefault: () -> throw Error('Should not be called!'),
        })

        lw.onFieldKeyDown({
            keyCode: 20,
            currentTarget: {
                name: 'age'
            },
            preventDefault: done
        })

