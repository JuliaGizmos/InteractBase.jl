@require Blink begin

using Blink

function Blink.body!(p::Page, x::AbstractWidget)
    Blink.body!(p, WebIO.render(x))
end

function Blink.body!(p::Window, x::AbstractWidget)
    Blink.body!(p, WebIO.render(x))
end

end
