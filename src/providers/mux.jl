@require Mux begin

using Mux

Mux.Response(o::Widget) = Mux.Response(o.node)

end
