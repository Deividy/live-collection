_ = require('underscore')

liveCollection = require('../src')

describe 'LiveCollection', () ->
    it 'keeps sort order when adding objects', () ->
        addOrders = [
            [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ]
            [ 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 ]
            [ 8, 4, 6, 2, 1, 0, 3, 7, 9, 5 ]
            [ 0, 1, 9, 7, 5, 3, 2, 4, 6, 8 ]
            [ 5, 1, 2, 3, 4, 6, 7, 8, 9, 0 ]
        ]

        expected = ( {id: n } for n in [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 ])

        for order in addOrders
            c = liveCollection()

            for n, cnt in order
                c.merge(id: n)
                expected = ( { id: n } for n in order.slice(0, cnt + 1).sort() )
                c.items.should.eql(expected)

                for item, idx in c.items
                    c.hasRightIndex(item, idx).should.be.true

