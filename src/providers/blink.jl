@require Blink begin

function Blink.body!(p::Blink.Page, x::AbstractWidget)
    Blink.body!(p, WebIO.render(x))
end

function Blink.body!(p::Blink.Window, x::AbstractWidget)
    Blink.body!(p, WebIO.render(x))
end

end
