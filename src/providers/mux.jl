@require Mux begin

using Mux

Mux.Response(o::AbstractUI) = Mux.Response(layout(o))

end
