@require Juno begin

using Juno

Juno.render(i::Juno.PlotPane, n::AbstractUI) =
    Juno.render(i, WebIO.render(n))

Juno.render(i::Juno.Editor, n::AbstractUI) =
    Juno.render(i, WebIO.render(n))

media(AbstractUI, Media.Graphical)

end
