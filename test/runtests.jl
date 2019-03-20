using Random
using InteractBase, Observables, OrderedCollections, Colors, WebIO, CSSUtil
using Widgets
using Dates
import InteractBase: widgettype
import Widgets: components

using Test

include("test_observables.jl")
include("test_theme.jl")
include("test_deps.jl")
