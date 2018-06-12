@require Juno begin

using Juno

Juno.render(i::Juno.PlotPane, n::AbstractUI) =
    Juno.render(i, layout(n))

Juno.render(i::Juno.Editor, n::AbstractUI) =
    Juno.render(i, layout(n))

media(AbstractUI, Media.Graphical)

end
