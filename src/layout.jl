center(w) = flex_row(w)
center(w::Widget) = w
center(w::Widget{:toggle}) = flex_row(w)

manipulatelayout(::WidgetTheme) = t -> node(:div, map(center, values(components(t)))..., map(center, t.output))
