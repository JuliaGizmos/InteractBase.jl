@require Juno begin

using Juno

Juno.render(i::Juno.PlotPane, n::Widget) =
    Juno.render(i, n.node)

Juno.render(i::Juno.Editor, n::Widget) =
    Juno.render(i, n.node)

media(Widget, Media.Graphical)

end
