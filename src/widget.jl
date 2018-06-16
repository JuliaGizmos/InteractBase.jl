export observe, Widget

mutable struct Widget{T, S<:Union{WebIO.Scope, Void}} <: AbstractUI
    node::Union{WebIO.Scope, WebIO.Node}
    primary_scope::S
    primary_obs::Observable
    Widget{T}(n::Union{WebIO.Scope, WebIO.Node}, s::S, o::Observable) where {T, S<:Union{WebIO.Scope, Void}} =
        new{T,S}(n, s, o)
end

Widget{T}(node::WebIO.Node, primary_obs::Observable) where {T} = Widget{T}(node, nothing, primary_obs)
Widget{T}(primary_scope::Scope, primary_obs) where {T} = Widget{T}(primary_scope, primary_scope, primary_obs)
Widget{T}(widget::Widget, obs=widget.primary_obs) where {T} = Widget{T}(widget.node, widget.primary_scope, obs)
Widget{T}(node, scope, obs::AbstractString) where {T} = Widget{T}(node, scope, scope[obs])

function (w::Widget)(args...; kwargs...)
    w.node = w.node(args...; kwargs...)
    return w
end

widgettype(::Widget{T}) where {T} = T

layout(x::Widget) = x.node

WebIO.render(u::AbstractUI) = layout(u)

Base.show(io::IO, m::MIME"text/plain", u::AbstractUI) = show(io, m, WebIO.render(u))

function Base.show(io::IO, m::MIME"text/html", x::AbstractUI)
    if !isijulia()
        show(io, m, WebIO.render(x))
    else
        write(io, "<div class='tex2jax_ignore $(getclass(:ijulia))'>\n")
        show(io, m, WebIO.render(x))
        write(io, "\n</div>")
    end
end

# mapping from widgets to respective scope
scope(widget::Scope) = widget
scope(widget::Widget) =  widget.primary_scope
hasscope(widget::Widget) = true
hasscope(widget::Widget{<:Any, Void}) = false

# users access a widgest's Observable via this function
observe(x::Observable) = x
observe(widget::Widget) = widget.primary_obs
observe(widget, i) = getindex(widget, i)

Base.getindex(widget::Widget, x) = getindex(scope(widget), x)
Base.getindex(widget::Widget{<:Any, Void}, x) = error("Indexing is only implemented for widgets with a primary scope")

"""
sets up a primary scope for widgets
"""
function primary_scope!(w::Widget, sc)
    hasscope(w) || error("primary_scope! can only be called on widgets with a primary scope")
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

function wrapfield(T::WidgetTheme, ui, f = Node(:div, className = getclass(:div, "field")))
    wrap(NativeHTML(), ui, f)
end

function wrap(T::WidgetTheme, ui, f = identity)
    ui.node = f(ui.node)
    ui
end

wrap(T::WidgetTheme, ui::Node, f = identity) = f(ui)
