@require Juno begin

using Juno

Juno.render(i::Juno.PlotPane, n::AbstractWidget) =
    Juno.render(i, WebIO.render(n))

Juno.render(i::Juno.Editor, n::AbstractWidget) =
    Juno.render(i, WebIO.render(n))

media(AbstractWidget, Media.Graphical)

end
