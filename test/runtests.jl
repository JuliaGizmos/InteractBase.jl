using InteractBase, Observables, DataStructures, Colors, WebIO, CSSUtil

import InteractBase: widgettype
import Widgets: components

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

include("test_observables.jl")
