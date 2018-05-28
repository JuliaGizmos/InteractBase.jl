module InteractBase

using WebIO, Vue, DataStructures, Observables, CSSUtil, Colors

export filepicker, datepicker, timepicker, colorpicker, spinbox

export autocomplete, input, dropdown, checkbox, textbox, button, slider, toggle

export radiobuttons, togglebuttons, tabs, checkboxes

export mask

export settheme!, resettheme!, gettheme, NativeHTML

export slap_design!

abstract type WidgetTheme; end
struct NativeHTML<:WidgetTheme; end

include("backends.jl")
include("widget_utils.jl")
include("input.jl")
include("optioninput.jl")
include("defaults.jl")
include("manipulate.jl")

end # module
