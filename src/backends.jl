libraries(::WidgetTheme) = [style_css]

Base.@deprecate_binding backend Widgets.backends

settheme!(b::WidgetTheme) = Widgets.set_backend!(b)
gettheme() = Widgets.get_backend()
resettheme!() = Widgtes.reset_backend!()
