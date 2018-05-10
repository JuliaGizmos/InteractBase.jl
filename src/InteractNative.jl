module InteractNative

using WebIO, Vue

export choosefile, autocomplete, input, dropdown, checkbox, textbox, button, slider, toggle

abstract type CSSFramework; end
struct NativeHTML<:CSSFramework; end

include("backends.jl")
include("widget_utils.jl")
include("input.jl")
include("optioninput.jl")
include("defaults.jl")

end # module
