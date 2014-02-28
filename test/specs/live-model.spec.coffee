{ _, liveCollection, liveModel } = @

liveCollectionEmpty = liveCollection()
liveCollectionWithAttributes = liveCollection({
    attributes: [ 'id', 'name', 'karma', 'newAttribute' ]
})

model = { id: 1, name: 'Anderson', karma: 50 }

describe 'LiveModel', () ->
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
