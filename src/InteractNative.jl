module InteractNative

using WebIO, Vue

export choosefile, autocomplete, input, dropdown, checkbox, textbox, button, slider

abstract type CSSFramework; end
struct NativeHTML<:CSSFramework; end

include("widget_utils.jl")
include("input.jl")
include("optioninput.jl")
include("defaults.jl")

end # module
