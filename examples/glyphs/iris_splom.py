
import os
from math import pi

from bokeh.sampledata.iris import flowers
from bokeh.objects import (
    ColumnDataSource, GlyphRenderer, Grid, GridPlot, LinearAxis, Plot,
    DataRange1d, DataRange1d, PanTool, ZoomTool
)
from bokeh.glyphs import Circle, Text
from bokeh import session

colormap = {'setosa': 'red', 'versicolor': 'green', 'virginica': 'blue'}

flowers['color'] = flowers['species'].map(lambda x: colormap[x])

source = ColumnDataSource(
    data=dict(
        petal_length=flowers['petal_length'],
        petal_width=flowers['petal_width'],
        sepal_length=flowers['sepal_length'],
        sepal_width=flowers['sepal_width'],
        color=flowers['color']
    )
)

xdr = DataRange1d(start=-1, end=9, sources=[source.columns("petal_length")])
ydr = DataRange1d(start=-1, end=9, sources=[source.columns("petal_length")])

pan = PanTool(dataranges=[xdr,ydr], dimensions=["x","y"])
zoom = ZoomTool(dataranges=[xdr,ydr], dimensions=["x","y"])

def make_plot(xname, yname, xax=False, yax=False, text=None):
    plot = Plot(
        x_range=xdr, y_range=ydr, data_sources=[source], background_fill="#ffeedd",
        width=250, height=250, border_fill='white', title="",
        border_symmetry="", min_border=2)
    objs = []
    if xax:
        label = " ".join(xax.split('_'))
        xaxis = LinearAxis(plot=plot, dimension=0, location="bottom",
            major_tick_in=0, axis_label=label, axis_label_text_color="lightgrey", axis_label_text_font_size="10pt")
        objs.append(xaxis)
    if yax:
        label = " ".join(yax.split('_'))
        yaxis = LinearAxis(plot=plot, dimension=1, location="left",
            major_tick_in=0, axis_label=label, axis_label_text_color="lightgrey", axis_label_text_font_size="8pt")
        objs.append(yaxis)
    xgrid = Grid(plot=plot, dimension=0)
    ygrid = Grid(plot=plot, dimension=1)
    circle = Circle(x=xname, y=yname, fill_color="color",
                    fill_alpha=0.2, radius=2, line_color="color")
    circle_renderer = GlyphRenderer(
        data_source = source,
        xdata_range = xdr,
        ydata_range = ydr,
        glyph = circle,
    )
    plot.renderers.append(circle_renderer)
    plot.tools = [pan, zoom]
    if text:
        label = " ".join(text.split('_'))
        text = Text(x=4, y=4, text=label, angle=pi/4, text_font_style="bold",
                    text_baseline="top", text_color="#ffaaaa", text_alpha=0.2,
                    text_align="center", text_font_size="28pt")
        text_renderer = GlyphRenderer(
            data_source=source,
            xdata_range = xdr,
            ydata_range = ydr,
            glyph = text,
        )
        plot.renderers.append(text_renderer)
        objs.append(text_renderer)
    return plot, objs + [circle_renderer, xgrid, ygrid]

sess = session.HTMLFileSession("iris_splom.html")
attrs = ["petal_length", "petal_width", "sepal_width", "sepal_length"]

plots = []
for y in attrs:
    row = []
    for x in attrs:
        xax = x if (y == attrs[-1]) else None
        yax = y if (x == attrs[0]) else None
        text = x if (x==y) else None
        plot, objs = make_plot(y, x, xax, yax, text)
        sess.add(plot, *objs)
        row.append(plot)
    plots.append(row)

grid = GridPlot(children=plots)

sess.add(source, xdr, ydr, pan, zoom)
sess.add(grid)
sess.plotcontext.children.append(grid)
sess.save(js="relative", css="relative", rootdir=os.path.abspath("."))

try:
    import webbrowser
    webbrowser.open("file://" + os.path.abspath("iris_splom.html"))
except:
    pass
