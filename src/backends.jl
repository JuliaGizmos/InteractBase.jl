libraries(::WidgetTheme) = [style_css]

Base.@deprecate_binding backend Widgets.backends

settheme!(b::WidgetTheme) = isa(Widgets.get_backend(), WidgetTheme) && Widgets.set_backend!(b)
gettheme() = isa(Widgets.get_backend(), WidgetTheme) ? Widgets.get_backend() : nothing
resettheme!() = isa(Widgets.get_backend(), WidgetTheme) && Widgets.reset_backend!()
