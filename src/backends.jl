libraries(::WidgetTheme) = ["/pkg/InteractBase/all.js"]

backend = WidgetTheme[NativeHTML()]

settheme!(b::WidgetTheme) = push!(backend, b)
gettheme() = last(backend)
resettheme!() = pop!(backend)
