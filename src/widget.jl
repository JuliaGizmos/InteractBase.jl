export observe, Widget

mutable struct Widget{T}
    typ::Val{T}
    node::Union{WebIO.Scope, WebIO.Node}
    primary_scope::WebIO.Scope
    primary_obs::Observable
end

Widget(typ, primary_scope::Scope, primary_obs::Observable) = Widget(typ, primary_scope, primary_scope, primary_obs)
Widget(typ, widget::Widget, obs::Observable=widget.primary_obs) = Widget(typ, widget.node, widget.primary_scope, obs)
Widget(typ, scope, obs::AbstractString) = Widget(typ, scope, scope[obs])
Widget(typ, node, scope, obs::AbstractString) = Widget(typ, node, scope, scope[obs])

widgettype(::Widget{T}) where {T} = T

Base.show(io::IO, m::MIME"text/html", x::Widget) = show(io, m, x.node)
Base.show(io::IO, m::MIME"text/plain", x::Widget) = show(io, m, x.node)

# mapping from widgets to respective scope
scope(widget::Scope) = widget
scope(widget::Widget) =  widget.primary_scope

# users access a widgest's Observable via this function
observe(widget::Widget) = widget.primary_obs
observe(widget, i) = getindex(widget, i)

Base.getindex(widget::Widget, x) = getindex(scope(widget), x)

"""
sets up a primary scope for widgets
"""
function primary_scope!(w::Widget, sc)
    w.primary_scope = sc
end

"""
sets up a primary observable for every
widget for use in @manipulate
"""
function primary_obs!(w, ob)
    w.primary_obs = ob
end
primary_obs!(w, ob::AbstractString) = primary_obs!(w, w[ob])

function wrap(T::WidgetTheme, ui, f = dom"div.field")
    ui.node = f(ui.node)
    ui
end
