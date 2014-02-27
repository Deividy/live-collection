_ = require('underscore')

liveCollection = require('../src')

testCollection = (opt = {}) ->
    c = liveCollection(opt)

    events = {
        total: () ->
            @adds.length + @updates.length + @removes.length + @counts.length + @resets.length

        reset: () ->
            @adds = []
            @updates = []
            @removes = []
            @resets = []
            @counts = []
    }

    events.reset()

    c.on({
        "add": (obj, index) -> events.adds.push({ obj, index })
        "update": (obj, index) -> events.updates.push({ obj, index })
        "remove": (obj, index) -> events.removes.push({ obj, index })
        "reset": (items, count) -> events.resets.push({ items, count: items.length })
        "count": (count) -> events.counts.push(count)
    })

    c.getEvents = () -> events
    return c

karmaCollection = () ->
    testCollection({
        comparator: (a, b) -> @comparePrimitive(b.karma, a.karma)
        belongs: (a) -> a.karma > 50
    })

describe 'LiveCollection', () ->
    it 'keeps sort order when adding objects', () ->
        addOrders = [
            [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
            [ 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 ]
            [ 8, 4, 6, 2, 1, 0, 3, 7, 9, 5 ]
            [ 0, 1, 9, 7, 5, 3, 2, 4, 6, 8 ]
            [ 5, 1, 2, 3, 4, 6, 7, 8, 9, 0 ]
        ]

        expected = ( {id: n} for n in [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ])

        for order in addOrders
            c = testCollection()

            for n, cnt in order
                c.merge(id: n)
                expected = ( { id: n } for n in order.slice(0, cnt + 1).sort() )
                c.items.should.eql(expected)

                for item, idx in c.items
                    c.hasRightIndex(item, idx).should.be.true

            events = c.getEvents()
            events.total().should.eql(20)
            events.counts.should.eql([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
            events.adds.length.should.eql(10)


    karmaArray = () -> [
        { id: 0, name: 'sue', karma: 1000 }
        { id: 1, name: 'gary', karma: 15 }
        { id: 2, name: 'john', karma: 300 }
        { id: 3, name: 'emily', karma: 30 }
        { id: 4, name: 'richard', karma: 200 }
        { id: 5, name: 'parnas', karma: 100 }
    ]

    doKarmaAdds = () ->
        c = karmaCollection()

        a = karmaArray()
        c.merge(a)

        a = (obj for obj in a when obj.karma > 50)
        c.items.should.eql(a)
        events = c.getEvents()
        events.adds.length.should.eql(4)
        return { c, a, events }

    it 'respects belongs() when adding', () ->
        doKarmaAdds()

    it 'does updates', () ->
        { c, a, events } = doKarmaAdds()
        events.reset()
        a[0].karma = 1001
        a[1].karma = 301

        c.merge(a)
        c.items.should.eql(a)
        events.total().should.eql(2)
        events.updates.should.eql([
            { obj: a[0], index: 0 }
            { obj: a[1], index: 1 }
        ])


    it 'keeps sort order on updates', () ->
        { c, a, events } = doKarmaAdds()

        a[0].karma = 150 # sue loses ground
        a[1].karma = 1200 # gary soars

        events.reset()
        c.merge(a)

        c.items.should.eql(_.sortBy(a, (o) -> -o.karma))

        # first sue got removed from index 0, added in 2
        events.removes.should.eql([ { obj: a[0], index: 0 } ])
        events.adds.should.eql( [ { obj: a[0], index: 2 } ])

        # sue's remove/add generates count events 
        events.counts.should.eql([3, 4])

        # by this point gary was already in position 0, and then we get his
        # update
        events.updates.should.eql( [ { obj: a[1], index: 0 } ])

        
    it 'does not fire spurious updates', () ->
        { c, a, events } = doKarmaAdds()
        events.reset()
        c.merge(a) for i in [0..10]
        events.total().should.eql(0)

    it 'respects belongs() when updating', () ->
        { c, a, events } = doKarmaAdds()

        events.reset()
        # sue's fall from grace
        a[0].karma = 49
        c.merge(a)

        sue = a.shift()
        c.items.should.eql(a)
        events.total().should.eql(2)
        events.counts.should.eql([3])
        events.removes.should.eql([{ obj: sue, index: 0 }])


    it 'respects the cloneBeforeAdd flag', () ->
        o = { id: 10, name: 'Kasparov' }
        c = liveCollection(cloneBeforeAdd: false)
        c.merge(o)
        c.items[0].should.equal(o)

        c = liveCollection()
        c.merge(o)
        c.items[0].should.not.equal(o)
        c.items[0].should.eql(o)


    it 'resets the collection', () ->
        a = karmaArray()
        k = karmaCollection()

        k.reset(a)

        { c } = doKarmaAdds()
        k.items.should.eql(c.items)

        events = k.getEvents()
        events.total().should.eql(2)
        events.resets.should.eql([{ items: k.items, count: k.items.length }])
        events.counts.should.eql([4])

    it 'clears properly on reset', () ->
        c = testCollection(
            { comparator: (a, b) -> @comparePrimitive(a.id, b.id) }
        )

        c.merge(id: 1)
        c.merge(id: 2)
        c.merge(id: 3)

        items = [ { id: 10 }, { id: 11} ]
        c.reset(items)
        c.items.should.eql(items)
        _.keys(c.byId).should.eql(['10', '11'])
