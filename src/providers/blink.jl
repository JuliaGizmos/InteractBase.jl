@require Blink begin

using Blink

function Blink.body!(p::Page, x::Widget)
    Blink.body!(p, x.node)
end

function Blink.body!(p::Window, x::Widget)
    Blink.body!(p, x.node)
end

end
