module InteractBase

using WebIO, Vue

export choosefile, autocomplete, input, dropdown, checkbox, textbox, button, slider, toggle

export settheme!, NativeHTML

export slap_design!

abstract type WidgetTheme; end
struct NativeHTML<:WidgetTheme; end

include("backends.jl")
include("widget_utils.jl")
include("input.jl")
include("optioninput.jl")
include("defaults.jl")

end # module
