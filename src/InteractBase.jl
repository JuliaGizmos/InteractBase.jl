module InteractBase

using WebIO, OrderedCollections, Observables, CSSUtil, Colors, JSExpr
import Observables: ObservablePair, AbstractObservable
import JSExpr: JSString
using Random
using Dates
using Base64: stringmime
using JSON
using Knockout
using Knockout: js_lambda
using Widgets
import Widgets:
    observe,
    AbstractWidget,
    div,
    Widget,
    widget,
    widgettype,
    @layout!,
    components,
    input,
    spinbox,
    textbox,
    textarea,
    autocomplete,
    datepicker,
    timepicker,
    colorpicker,
    checkbox,
    toggle,
    filepicker,
    opendialog,
    savedialog,
    slider,
    rangeslider,
    rangepicker,
    button,
    dropdown,
    radiobuttons,
    checkboxes,
    toggles,
    togglebuttons,
    tabs,
    entry,
    latex,
    alert,
    highlight,
    notifications,
    confirm,
    togglecontent,
    tabulator,
    accordion,
    mask,
    tooltip!,
    wdglabel,
    slap_design!,
    @manipulate,
    manipulatelayout,
    triggeredby,
    onchange

import Observables: throttle, _val

export observe, Widget, widget

export @manipulate

export filepicker, opendialog, savedialog, datepicker, timepicker, colorpicker, spinbox

export autocomplete, input, dropdown, checkbox, textbox, textarea, button, toggle, togglecontent

export slider, rangeslider, rangepicker

export radiobuttons, togglebuttons, tabs, checkboxes, toggles

export latex, alert, confirm, highlight, notifications, accordion, tabulator, mask

export onchange

export settheme!, resettheme!, gettheme, availablethemes, NativeHTML

export slap_design!

abstract type WidgetTheme<:Widgets.AbstractBackend; end
struct NativeHTML<:WidgetTheme; end

const font_awesome = joinpath(@__DIR__, "..", "assets", "all.js")
const prism_js = joinpath(@__DIR__, "..", "assets", "prism.js")
const prism_css = joinpath(@__DIR__, "..", "assets", "prism.css")
const highlight_css = joinpath(@__DIR__, "..", "assets", "highlight.css")
const nouislider_min_js = joinpath(@__DIR__, "..", "assets", "nouislider.min.js")
const nouislider_min_css = joinpath(@__DIR__, "..", "assets", "nouislider.min.css")
const style_css = joinpath(@__DIR__, "..", "assets", "style.css")

include("classes.jl")
include("backends.jl")
include("utils.jl")
include("input.jl")
include("slider.jl")
include("optioninput.jl")
include("layout.jl")
include("output.jl")
include("modifiers.jl")

function __init__()
    if Widgets.get_backend() === Widgets.DummyBackend()
        Widgets.set_backend!(NativeHTML())
    end
end

end # module
