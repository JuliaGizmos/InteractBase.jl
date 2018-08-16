export observe, Widget

WebIO.render(u::Widget) = WebIO.render(u.layout(u))

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
