@require Blink begin

using Blink

function Blink.body!(p::Page, x::AbstractUI)
    Blink.body!(p, WebIO.render(x))
end

function Blink.body!(p::Window, x::AbstractUI)
    Blink.body!(p, WebIO.render(x))
end

end
