
define [
  "underscore",
  "jquery",
  "./plot",
  "range/data_range1d",
  "range/range1d",
  "renderer/annotation/legend",
  "renderer/glyph/glyph_factory",
  "renderer/guide/linear_axis",
  "renderer/guide/grid",
  "renderer/overlay/box_selection",
  "source/column_data_source",
  "tool/box_select_tool",
  "tool/pan_tool",
  "tool/preview_save_tool",
  "tool/resize_tool",
  "tool/wheel_zoom_tool",
  "renderer/guide/datetime_axis",
], (_, $, Plot, DataRange1d, Range1d, Legend, GlyphFactory, LinearAxis, Grid, BoxSelection, ColumnDataSource, BoxSelectTool, PanTool, PreviewSaveTool, ResizeTool, WheelZoomTool, DatetimeAxis) ->

  create_sources = (data) ->
    if not _.isArray(data)
      data = [data]
    sources = []
    for d in data
      if d instanceof ColumnDataSource.Model
        sources.push(d)
      else
        sources.push(ColumnDataSource.Collection.create({data: d}))
    return sources

  create_range = (range, sources, columns) ->
    if range == 'auto'
      return DataRange1d.Collection.create(
        sources: ({ref: s.ref(), columns: columns} for s in sources)
      )
    else if range instanceof Range1d.Model
      return range
    else
      return Range1d.Collection.create({start: range[0], end: range[1]})

  create_glyphs = (plot, glyphspecs, sources, nonselection_glyphspecs) ->
    glyphs = []
    if not _.isArray(glyphspecs)
      glyphspecs = [glyphspecs]

    if sources.length == 1
      sources = (sources[0] for x in glyphspecs)

    if not nonselection_glyphspecs?
      nonselection_glyphspecs = {
        fill_alpha: 0.1
        line_alpha: 0.1
      }
    if not _.isArray(nonselection_glyphspecs)
      nonselection_glyphspecs = (nonselection_glyphspecs for x in glyphspecs)

    for val in _.zip(glyphspecs, nonselection_glyphspecs, sources)
      [spec, non_spec, source] = val
      glyph = GlyphFactory.Collection.create({
        parent: plot.ref()
        data_source: source.ref()
        glyphspec: spec
        nonselection_glyphspec: non_spec
      })
      glyphs.push(glyph)

    return glyphs

  add_axes = (plot, xaxes, yaxes) ->
    axes = []
    if xaxes
      if xaxes == true
        xaxes = ['min', 'max']
      if not _.isArray(xaxes)
        xaxes = [xaxes]
      if xaxes[0]=="datetime"

        for loc in ['min','max']
          axis = DatetimeAxis.Collection.create(
          #axis = LinearAxis.Collection.create(
            dimension: 0
            axis_label: 'x'
            location: loc
            parent: plot.ref()
            plot: plot.ref())
          axes.push(axis)
      else
        for loc in xaxes
          axis = LinearAxis.Collection.create(
            dimension: 0
            axis_label: 'x'
            location: loc
            parent: plot.ref()
            plot: plot.ref())
          axes.push(axis)
    if yaxes
      if yaxes == true
        yaxes = ['min', 'max']
      if not _.isArray(yaxes)
        yaxes = [yaxes]
      for loc in yaxes
        axis = LinearAxis.Collection.create(
          dimension: 1
          axis_label: 'y'
          location: loc
          parent: plot.ref()
          plot: plot.ref()
        )
        axes.push(axis)
    plot.add_renderers(a.ref() for a in axes)

  add_grids = (plot, xgrid, ygrid) ->
    grids = []
    if xgrid
      grid = Grid.Collection.create(
        dimension: 0
        parent: plot.ref()
        plot: plot.ref()
      )
      grids.push(grid)
    if ygrid
      grid = Grid.Collection.create(
        dimension: 1
        parent: plot.ref()
        plot: plot.ref()
      )
      grids.push(grid)
      plot.add_renderers(g.ref() for g in grids)

  add_tools = (plot, tools, glyphs, xdr, ydr) ->
    if tools == false
      return

    if tools == true
      tools = "pan,wheel_zoom,select,resize,preview"
    added_tools = []

    if tools.indexOf("pan") > -1
      pan_tool = PanTool.Collection.create(
        dataranges: [xdr.ref(), ydr.ref()]
        dimensions: ['width', 'height']
      )
      added_tools.push(pan_tool)

    if tools.indexOf("wheel_zoom") > -1
      wheel_zoom_tool = WheelZoomTool.Collection.create(
        dataranges: [xdr.ref(), ydr.ref()]
        dimensions: ['width', 'height']
      )
      added_tools.push(wheel_zoom_tool)

    if tools.indexOf("select") > -1
      select_tool = BoxSelectTool.Collection.create(
        renderers: (g.ref() for g in glyphs)
      )
      select_overlay = BoxSelection.Collection.create(
        tool: select_tool.ref()
      )
      added_tools.push(select_tool)
      plot.add_renderers([select_overlay.ref()])

    if tools.indexOf("resize") > -1
      resize_tool = ResizeTool.Collection.create()
      added_tools.push(resize_tool)

    if tools.indexOf("preview") > -1
      preview_tool = PreviewSaveTool.Collection.create()
      added_tools.push(preview_tool)

    plot.set_obj('tools', added_tools)

  add_legend = (plot, legend, glyphs) ->
    if legend
      legends = {}
      for g, idx in glyphs
        legends[legend + String(idx)] = [g.ref()]
      legend_renderer = Legend.Collection.create({
        parent: plot.ref()
        plot: plot.ref()
        orientation: "top_right"
        legends: legends
      })
      plot.add_renderers([legend_renderer.ref()])

  make_plot = (glyphspecs, data, {nonselected, title, dims, xrange, yrange, xaxes, yaxes, xgrid, ygrid, xdr, ydr, tools, legend}) ->
    nonselected ?= null
    title  ?= ""
    dims   ?= [400, 400]
    xrange ?= 'auto'
    yrange ?= 'auto'
    xaxes  ?= true
    yaxes  ?= true
    xgrid  ?= true
    ygrid  ?= true
    tools  ?= true
    legend ?= false

    sources = create_sources(data)

    xdr = create_range(xrange, sources, ['x'])
    ydr = create_range(yrange, sources, ['y'])

    plot = Plot.Collection.create(
      x_range: xdr.ref()
      y_range: ydr.ref()
      canvas_width: dims[0]
      canvas_height: dims[1]
      outer_width: dims[0]
      outer_height: dims[1]
      title: title
    )

    glyphs = create_glyphs(plot, glyphspecs, sources, nonselected)
    plot.add_renderers(g.ref() for g in glyphs)

    add_axes(plot, xaxes, yaxes)
    add_grids(plot, xgrid, ygrid)
    add_tools(plot, tools, glyphs, xdr, ydr)
    add_legend(plot, legend, glyphs)

    return plot


  show = (plot) ->
    div = $('<div class="plotdiv"></div>')
    $('body').append(div)
    myrender  =  ->
      view = new plot.default_view(model: plot)
      window.pview = view
      div.append(view.$el)
      console.log("added plot: " + plot.get('title'))
    _.defer(myrender)


  return {
    "make_plot": make_plot,
    "create_glyphs": create_glyphs,
    "show": show,
  }
