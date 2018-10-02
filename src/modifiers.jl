"""
`tooltip!(wdg::AbstractWidget, tooltip; className = "")`

Experimental. Add a tooltip to widget wdg. `tooltip` is the text that will be shown and `className`
can be used to customize the tooltip, for example `is-tooltip-bottom` or `is-tooltip-danger`.
"""
function tooltip!(wdg::AbstractWidget, args...; kwargs...)
    tooltip!(node(wdg)::Node, args...; kwargs...)
    return wdg
end

function tooltip!(n::Node, tooltip; className = "")
    d = props(n)
    get!(d, :attributes, Dict{String, Any})
    get!(d, :className, "")
    d[:attributes]["data-tooltip"] = tooltip
    d[:className] = mergeclasses(d[:className], className, "tooltip")
    n
end

function triggeredby!(o::AbstractObservable, a::AbstractObservable, b::AbstractObservable)
    f = on(t -> setindex!(a, t), o)
    on(t -> setindex!(o, a[], notify = x -> x != f), b)
    o
end

triggeredby(a::AbstractObservable{T}, b::AbstractObservable) where {T} =
    triggeredby!(Observable{T}(a[]), a, b)

"""
`onchange(w::AbstractWidget, change = w[:changes])`

Return a widget that's identical to `w` but only updates on `change`. For a slider it corresponds to releasing it
and for a textbox it corresponds to losing focus.

## Examples

```julia
sld = slider(1:100) |> onchange # update on release
txt = textbox("Write here") |> onchange # update on losing focuse
```
"""
function onchange(w::AbstractWidget{T}, change = w[:changes]) where T
    o = triggeredby(w, change)
    Widget{T}(w, output = o)
end
