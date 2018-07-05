@require Mux begin

using Mux

Mux.Response(o::AbstractWidget) = Mux.Response(WebIO.render(o))

end
