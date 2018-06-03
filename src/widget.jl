export observe, Widget

mutable struct Widget{T}
    typ::T
    node::Union{WebIO.Scope, WebIO.Node}
    primary_scope::WebIO.Scope
    primary_obs::Observable
end

Widget(typ, primary_scope::Scope, primary_obs::Observable) = Widget(typ, primary_scope, primary_scope, primary_obs)
Widget(typ, widget::Widget, obs::Observable=widget.primary_obs) = Widget(typ, widget.node, widget.primary_scope, obs)
Widget(typ, scope, obs::AbstractString) = Widget(typ, scope, scope[obs])
Widget(typ, node, scope, obs::AbstractString) = Widget(typ, node, scope, scope[obs])

# Widget(typ, node, primary_scope) = Widget(typ, node, primary_scope, nothing)
# Widget(typ, primary_scope::WebIO.Scope, primary_obs::Union{Observable, Void}=nothing) =
#     Widget(typ, primary_scope, primary_scope, primary_obs)
# Widget(typ, node::WebIO.Node, primary_obs::Union{Observable, Void}=nothing) =
#     Widget(typ, node, Nothing, primary_obs)

WebIO.render(x::Widget) = WebIO.render(x.node)

# mapping from widgets to respective scope
scope(widget::Scope) = widget
scope(widget::Widget) =  widget.primary_scope

# users access a widgest's Observable via this function
observe(widget::Widget) = widget.primary_obs

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
    widgobs[w] = ob
end
primary_obs!(w, ob::String) = primary_obs!(w, w[ob])

function wrap(T::WidgetTheme, ui::Widget, f = dom"div.field")
    ui.node = f(ui.node)
    ui
end
