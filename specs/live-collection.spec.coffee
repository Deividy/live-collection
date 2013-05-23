_ = require('underscore')

liveCollection = require('../src')

testCollection = (opt = {}) ->
    events = {
        total: () -> @add.length + @update.length + @remove.length + @count.length
        reset: () ->
            @add = []
            @update = []
            @remove = []
            @count = []
    }

    events.reset()

    _.extend(opt, {
        onAdd: (obj, index) => events.add.push({ obj, index })
        onUpdate: (obj, index) => events.update.push({ obj, index })
        onRemove: (obj, index) => events.remove.push({ obj, index })
        onCount: (count) => events.count.push(count)
        getEvents: () => events
    })

    return liveCollection(opt)

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
            events.count.should.eql([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
            events.add.length.should.eql(10)


    doKarmaAdds = () ->
        c = karmaCollection()
        a = [
            { id: 0, name: 'sue', karma: 1000 }
            { id: 1, name: 'gary', karma: 15 }
            { id: 2, name: 'john', karma: 300 }
            { id: 3, name: 'emily', karma: 30 }
            { id: 4, name: 'richard', karma: 200 }
            { id: 5, name: 'parnas', karma: 100 }
        ]

        c.merge(a)

        a = (obj for obj in a when obj.karma > 50)
        c.items.should.eql(a)
        events = c.getEvents()
        events.add.length.should.eql(4)
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
        events.update.should.eql([
            { obj: a[0], index: 0 }
            { obj: a[1], index: 1 }
        ])
        
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
        events.count.should.eql([3])
        events.remove.should.eql([{ obj: sue, index: 0 }])
