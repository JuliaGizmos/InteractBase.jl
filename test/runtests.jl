using InteractBase, Observables, DataStructures, Colors, WebIO

import InteractBase: widgettype

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

include("component-util-tests.jl")
include("test_observables.jl")
