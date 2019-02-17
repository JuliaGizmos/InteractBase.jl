libraries(::WidgetTheme) = [style_css]

backend = WidgetTheme[NativeHTML()]

settheme!(b::WidgetTheme) = Widgets.set_backend!(b)
gettheme() = Widgets.get_backend()
resettheme!() = Widgtes.reset_backend!()
