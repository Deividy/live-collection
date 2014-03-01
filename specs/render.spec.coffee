{ liveCollection, liveRender, $ } = @

lr = lc = null

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
        lc.reset([ { id: 1, firstName: 'Deividy', lastName: 'Metheler', age: 23 } ])

        $container = $("ul#items li[data-rowid='1']")

        $container
            .find("input[name='firstName']").val()
            .should.eql("Deividy")

        $container
            .find("input[name='lastName']").val()
            .should.eql("Metheler")

        $container
            .find(".age").html()
            .should.eql("23")
