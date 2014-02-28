{ _, liveCollection, liveModel } = @

orderByName = () ->
    liveCollection({
        comparator: (a, b) -> @comparePrimitive(a.name, b.name)
    })

describe 'LiveCollection', () ->
    it 'accepts comparator', () ->
        c = orderByName()

        h = liveModel({ id: 0, name: "Harry Potter" }, c)
        a = liveModel({ id: 1, name: "Albus Dumbledore"}, c)

        c.merge([h, a])
        c.items.should.eql([a, h])

    it 'does not handle diacritics in string ordering', () ->
        c = orderByName()

        m = liveModel({ id: 0, name: "MIT" }, c)
        e = liveModel({ id: 1, name: "École Polytechnique" }, c)

        c.merge([m, e])
        c.items.should.eql([m, e])

    it 'ignores case in string ordering', () ->
        c = orderByName()

        third = liveModel({ id: 0, name: "Brutus" }, c)
        second = liveModel({ id: 1, name: "bazinga" }, c)
        fourth = liveModel({ id: 2, name: "Courtney" }, c)
        first = liveModel({ id: 3, name: "ana luiza" }, c)

        c.merge([third, second, fourth, first])
        c.items.should.eql([first, second, third, fourth])
