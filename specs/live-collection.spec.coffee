_ = require('underscore')

liveCollection = require('../src')

testCollection = (opt = {}) ->
    events = {
        add: [],
        update: [],
        remove: [],
        count: [],
        total: () -> @add.length + @update.length + @remove.length + @count.length
    }

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
        comparator: (a, b) -> @comparePrimitive(a.karma, b.karma)
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

    it 'respects belongs() when adding', () ->
        c = karmaCollection()
        a = [
            { id: 0, name: 'sue', karma: 1000 }
            { id: 1, name: 'gary', karma: 15 }
            { id: 2, name: 'john', karma: 300 }
            { id: 3, name: 'emily', karma: 30 }
            { id: 4, name: 'richard', karma: 200 }
        ]

        c.merge(a)

        a = _.filter(a, (e) -> e.karma > 50).reverse()
        c.items.should.eql(a)

    it 'respects belongs() when updating', () ->

