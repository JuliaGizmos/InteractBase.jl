@require Blink begin

using Blink

function Blink.body!(p::Page, x::AbstractUI)
    Blink.body!(p, layout(x))
end

function Blink.body!(p::Window, x::AbstractUI)
    Blink.body!(p, layout(x))
end

end
