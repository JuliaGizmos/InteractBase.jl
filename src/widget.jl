export observe, Widget

WebIO.render(u::Widget) = WebIO.render((u.update(u); u.layout(u)))

Base.show(io::IO, m::MIME"text/plain", u::AbstractWidget) = show(io, m, WebIO.render(u))

function Base.show(io::IO, m::MIME"text/html", x::AbstractWidget)
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
scope(widget::Widget) =  widget.scope
hasscope(widget::Widget) = widget.scope !== nothing
hasscope(widget::Scope) = true


"""
sets up a primary scope for widgets
"""
function primary_scope!(w::Widget, sc)
    hasscope(w) || error("primary_scope! can only be called on widgets with a primary scope")
    w.scope = sc
end

"""
sets up a primary observable for every
widget for use in @manipulate
"""
function primary_obs!(w, ob)
    w.output = ob
end
primary_obs!(w, ob::AbstractString) = primary_obs!(w, (w.scope)[ob])

function wrapfield(T::WidgetTheme, ui, f = Node(:div, className = getclass(:div, "field")))
    wrap(NativeHTML(), ui, f)
end

function wrap(T::WidgetTheme, ui, f = identity)
    ui.layout = f∘ui.layout
    ui
end

wrap(T::WidgetTheme, ui::Node, f = identity) = f(ui)
