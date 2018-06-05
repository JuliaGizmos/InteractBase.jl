libraries(::WidgetTheme) = String[]

backend = WidgetTheme[NativeHTML()]

settheme!(b::WidgetTheme) = push!(backend, b)
gettheme() = last(backend)
resettheme!() = pop!(backend)
