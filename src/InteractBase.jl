__precompile__()

module InteractBase

using WebIO, DataStructures, Observables, CSSUtil, Colors, JSExpr
import Observables: ObservablePair, AbstractObservable
import JSExpr: JSString
using Random
using Dates
using Base64: stringmime
using JSON
using Knockout
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
    input

import Observables: throttle, _val

export observe, Widget

export filepicker, datepicker, timepicker, colorpicker, spinbox

export autocomplete, input, dropdown, checkbox, textbox, textarea, button, toggle, togglecontent

export slider, rangeslider, rangepicker

export radiobuttons, togglebuttons, tabs, checkboxes, toggles

export latex, alert, confirm, highlight, notifications, accordion, tabulator, mask

export settheme!, resettheme!, gettheme, NativeHTML

export slap_design!

abstract type WidgetTheme; end
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
include("defaults.jl")
include("manipulate.jl")
include("output.jl")
include("modifiers.jl")

end # module
