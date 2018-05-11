libraries(::WidgetTheme) = String[]

backend = WidgetTheme[NativeHTML()]

settheme!(b::WidgetTheme) = push!(backend, b)
resettheme!() = pop!(backend)
