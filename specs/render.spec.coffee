{ liveCollection, liveRender, $ } = @

lr = lc = null

collection = () -> [
    { id: 1, firstName: 'Deividy', lastName: 'Metheler', age: 23 }
    { id: 2, firstName: 'Anderson', lastName: 'Silva', age: 38 }
    { id: 3, firstName: 'Snoopy', lastName: 'Dog', age: 1 }
    { id: 4, firstName: 'John', lastName: 'Doe', age: 69 }
]

describe 'LiveRender', () ->
    beforeEach () ->
        document.body.innerHTML = __html__['specs/template.html']

        lc = liveCollection()
        lr = liveRender({
            template: "#item",
            container: "ul#items",
            scrollWrapper: 'ul#items',
            templateVariable: 'data',
            liveCollection: lc
        })

    it 'reset live render', () ->
        lc.reset(collection())

        for item in collection()
            $container = $("ul#items li[data-rowid='#{item.id}']")

            $container
                .find("input[name='firstName']").val()
                .should.eql(item.firstName)

            $container
                .find("input[name='lastName']").val()
                .should.eql(item.lastName)

            $container
                .find(".age").html()
                .should.eql("#{item.age}")


    it 'test click event', (done) ->
        lr = liveRender({
            template: "#item",
            container: "ul#items",
            scrollWrapper: 'ul#items',
            templateVariable: 'data',
            liveCollection: lc,
            onClick: (item, ev) ->
                item.id.should.eql(1)
                item.firstName.should.eql('Deividy')
                item.lastName.should.eql('Metheler')
                item.age.should.eql(23)

                item.isDirty().should.be.false

                done()
        })

        lc.reset(collection())

        $("ul#items li[data-rowid='1']").click().triggerHandler('click')

    it 'test count event', (done) ->
        lr = liveRender({
            template: "#item",
            container: "ul#items",
            scrollWrapper: 'ul#items',
            templateVariable: 'data',
            liveCollection: lc,
            onCount: (count) ->
                count.should.eql(4)
                @.should.eql(lr)
                done()
        })

        lc.reset(collection())

    it 'test remove', () ->
        lc.reset(collection())

        $("[data-rowid='1']").length.should.eql(2)
        $("ul#items li[data-rowid='1']").length.should.eql(1)

        lc.remove({ id: 1 })

        $("[data-rowid='1']").length.should.eql(1)
        $("ul#items li[data-rowid='1']").length.should.eql(0)

    it '2way binding', () ->
        lc.reset(collection())

        $item = $("form div[data-rowid='1']")
        item = lc.tryGet({ id: 1 })

        item.wrap($item)

        $item.find("input[name='firstName']").val("Johny").triggerHandler("change")
        $item.find("input[name='age']").val(18).triggerHandler("change")

        item.firstName.should.eql("Johny")
        item.lastName.should.eql("Metheler")
        item.age.should.eql(18)

        $liItem = $("ul#items li[data-rowid='1']")

        $liItem.find("input[name='firstName']").val().should.eql("Johny")
        $liItem.find("input[name='lastName']").val().should.eql("Metheler")
        $liItem.find(".age").html().should.eql("18")



