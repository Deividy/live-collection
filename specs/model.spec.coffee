{ _, liveCollection, liveModel } = @

liveCollectionEmpty = liveCollection()
liveCollectionWithAttributes = liveCollection({
    attributes: [ 'id', 'name', 'karma', 'newAttribute' ]
})

model = { id: 1, name: 'Anderson', karma: 50 }
model2 = { id: 1, firstName: 'Deividy', lastName: 'Metheler', age: 23, karma: 10 }

describe 'LiveModel', () ->
    beforeEach () ->
        document.body.innerHTML = __html__['specs/template.html']

    it 'instantiante and get changes', () ->
        m = liveModel(model, liveCollectionEmpty)
        m.karma = 20

        m.isDirty().should.be.true

        m.changes().previousValues.should.eql({ karma: 50 })
        m.changes().newValues.should.eql({ karma: 20 })
        m.dirtyAttributes().should.eql([ 'karma' ])

    it 'ignore new attributes', () ->
        m = liveModel(model, liveCollectionEmpty)
        m.karma = 20

        # ignore new attributes, the live model should be initialized
        # with all the attributes, OR the liveCollection should have
        # the attributes configuration
        m.newAttribute = "New!"

        m.name = 'Deividy'

        m.isDirty().should.be.true
        m.dirtyAttributes().should.eql([ 'name', 'karma' ])

        m.changes().previousValues.should.eql({ karma: 50, name: 'Anderson' })
        m.changes().newValues.should.eql({ karma: 20, name: 'Deividy' })

     it 'use attributes from liveCollection', () ->
        m = liveModel(model, liveCollectionWithAttributes)
        m.karma = 20
        m.newAttribute = "New"

        m.isDirty().should.be.true
        m.dirtyAttributes().should.eql([ 'karma', 'newAttribute' ])

        m.changes().previousValues.should.eql({ karma: 50 })
        m.changes().newValues.should.eql({ karma: 20, newAttribute: 'New'})

    it 'refresh', () ->
        m = liveModel(model, liveCollectionEmpty)
        m.karma = 20

        m.isDirty().should.be.true
        m.dirtyAttributes().should.eql([ 'karma' ])

        m.changes().previousValues.should.eql({ karma: 50 })
        m.changes().newValues.should.eql({ karma: 20 })

        m.refresh()

        m.isDirty().should.be.false
        m.dirtyAttributes().should.eql([])

        m.changes().previousValues.should.eql({})
        m.changes().newValues.should.eql({})

    it 'test update DOM when wrap', () ->
        $container = $("form div[data-rowid='1']")

        $container.find("input[name='firstName']").val().should.eql("")
        $container.find("input[name='lastName']").val().should.eql("")
        $container.find("input[name='age']").val().should.eql("")
        $container.find(".karma").html().should.eql("")

        m = liveModel(model2, liveCollectionEmpty)
        m.wrap($container)

        $container.find("input[name='firstName']").val().should.eql("Deividy")
        $container.find("input[name='lastName']").val().should.eql("Metheler")
        $container.find("input[name='age']").val().should.eql("23")
        $container.find(".karma").html().should.eql("10")

    it 'should update DOM when set value', () ->
        $container = $("form div[data-rowid='1']")

        m = liveModel(model2, liveCollectionEmpty)
        m.wrap($container)

        $container.find("input[name='firstName']").val().should.eql("Deividy")
        $container.find("input[name='lastName']").val().should.eql("Metheler")
        $container.find("input[name='age']").val().should.eql("23")
        $container.find(".karma").html().should.eql("10")

        m.setValues({ karma: 99999, firstName: 'Chuck', lastName: 'Norris', age: 1000 })

        $container.find("input[name='firstName']").val().should.eql("Chuck")
        $container.find("input[name='lastName']").val().should.eql("Norris")
        $container.find("input[name='age']").val().should.eql("1000")
        $container.find(".karma").html().should.eql("99999")

    it 'should update model by DOM change', () ->
        $container = $("form div[data-rowid='1']")

        m = liveModel(model2, liveCollectionEmpty)
        m.wrap($container)

        $container.find("input[name='firstName']").val("Chuck").triggerHandler("change")
        $container.find("input[name='lastName']").val("Norris").triggerHandler("change")

        m.firstName.should.eql("Chuck")
        m.lastName.should.eql("Norris")


    it 'should get changes model by DOM change', () ->
        $container = $("form div[data-rowid='1']")

        m = liveModel(model2, liveCollectionEmpty)
        m.wrap($container)

        $container.find("input[name='firstName']").val("Chuck").triggerHandler("change")
        $container.find("input[name='lastName']").val("Norris").triggerHandler("change")

        m.changes().should.eql({
            id: 1,
            newValues: { firstName: 'Chuck', lastName: 'Norris' },
            previousValues: { firstName: 'Deividy', lastName: 'Metheler' }
        })
