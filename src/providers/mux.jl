@require Mux begin

using Mux

Mux.Response(o::AbstractUI) = Mux.Response(WebIO.render(o))

end
