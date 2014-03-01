@liveRender = (options) -> new LiveRender(options)

class LiveRender
    constructor: (options = {}) ->
        unless @render?
            tplContents = $(options.template).html()
            variable = options.templateVariable ? "data"
            template = _.template(tplContents, null, { variable })
            @render = (data) -> template(data)

        @container = $(options.container)

        @lc = options.liveCollection

        @lc.on("add", @add, @)
        @lc.on("update", @update, @)
        @lc.on("remove", @remove, @)
        @lc.on("reset", @reset, @)

        if _.isFunction(options.onCount)
            @lc.on("count", options.onCount, @)

        if _.isFunction(options.onClick)
            @container.on("click", (event) => @click(event, options.onClick))

    click: (e, handler) ->
        container = $(e.target).closest("[data-rowid]")

        if container.length == 0
            msg = "Unable to find containing element for click. You must render each data row " +
                'within an HTML element with a "data-rowid" attribute'

            throw new Error(msg)

        if container.length > 1
            throw new Error('Found multiple containing elements for click')

        id = Number(container.data("rowid"))
        # SHOULD: test with isGoodNumber here
        item = @lc.get(id)
        handler(item)

    add: (item, index) ->
        html = @render(item).trim()
        el = $(html).hide()
        if 0 == index
            el.prependTo(@container).fadeIn()
        else
            el.insertAfter(@container.children().eq(index - 1)).fadeIn()

    update: (item, index) ->
        html = @render(item).trim()
        @container.children().eq(index).replaceWith(html)

    remove: (item, index) -> @container.children().eq(index).remove()
    
    reset: (items) ->
        content = (@render(item) for item in items)
        @container.html(content)

    count: (count) -> @count.text(count)

@liveRender.Class = LiveRender
