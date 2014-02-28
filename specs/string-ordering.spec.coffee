_ = require('underscore')

liveCollection = require('../src/live-collection')

orderByName = () ->
    liveCollection({
        comparator: (a, b) -> @comparePrimitive(a.name, b.name)
    })

describe 'LiveCollection', () ->
    it 'accepts comparator', () ->
        c = orderByName()

        h = { id: 0, name: "Harry Potter" }
        a = { id: 1, name: "Albus Dumbledore"}

        c.merge([h, a])
        c.items.should.eql([a, h])

    it 'does not handle diacritics in string ordering', () ->
        c = orderByName()

        m = { id: 0, name: "MIT" }
        e = { id: 1, name: "École Polytechnique" }

        c.merge([m, e])
        c.items.should.eql([m, e])

    it 'ignores case in string ordering', () ->
        c = orderByName()

        third = { id: 0, name: "Brutus" }
        second = { id: 1, name: "bazinga" }
        fourth = { id: 2, name: "Courtney" }
        first = { id: 3, name: "ana luiza" }

        c.merge([third, second, fourth, first])
        c.items.should.eql([first, second, third, fourth])
