_length(v::AbstractArray) = length(v)
_length(::Any) = 1
_map(f, v::AbstractArray) = map(f, v)
_map(f, v) = f(v)

function format(x)
    io = IOBuffer()
    showcompact(io, x)
    String(io)
end

"""
```
function rangeslider(vals::AbstractArray;
                value=medianelement(vals),
                label=nothing, readout=true, kwargs...)
```

Experimental `slider` that accepts several "handles". Pass a vector to `value` with two values if you want to
select a range. In the future it will replace `slider`.
"""
function rangeslider(vals::AbstractArray; style = Dict(), label = nothing, value = medianelement(vals), orientation = "horizontal", readout = true)

    vals = vec(vals)
    formatted_vals = format.(vals)

    T = Observables._val(value) isa Vector ? Vector{eltype(vals)} : eltype(vals)
    value isa Observable || (value = Observable{T}(value))

    indices = 1:length(vals)
    f = x -> _map(t -> searchsortedfirst(vals, t), x)
    g = x -> vals[Int.(x)]
    index = ObservablePair(value, f = f, g = g).second

    preprocess = T<:Vector ? js"unencoded.map(Math.round)" : js"Math.round(unencoded[0])"

    scp = Scope(imports = [nouislider_min_js, nouislider_min_css])
    setobservable!(scp, "index", index)
    fromJS = Observable(scp, "fromJS", false)
    connect = _length(index[]) > 1 ? js"true" : js"[true, false]"
    min, max = 1, length(vals)

    id = "slider"*randstring()
    start = JSExpr.@js $index[]
    updateValue = JSExpr.@js function updateValue(values, handle, unencoded, tap, positions)
        $fromJS[] = true
        $index[] = $preprocess
    end
    tooltips = JSString("[" * join(fill(readout, _length(value[])), ", ") * "]")

    onimport(scp, js"""
        function (noUiSlider) {
            var vals = JSON.parse($(JSON.json(formatted_vals)));
            $updateValue
            var slider = document.getElementById($id);
            noUiSlider.create(slider, {
            	start: $start,
                step: 1,
                tooltips: $tooltips,
                connect: $connect,
                orientation: $orientation,
                format: {
                to: function ( value ) {
                    return vals[Math.round(value)-1];
                },
                from: function ( value ) {
                    return value;
                  }
                },
            	range: {
            		'min': $min,
            		'max': $max
            	},})

            slider.noUiSlider.on("slide", updateValue);
        }
        """)
    slap_design!(scp)
    onjs(index, @js function (val)
        if !$fromJS[]
            new_val = Array.isArray(val) ? val : [val]
            document.getElementById($id).noUiSlider.set(new_val)
        end
        $fromJS[] = false
    end)

    style = Dict{String, Any}(string(key) => val for (key, val) in style)
    haskey(style, "flex-grow") || (style["flex-grow"] = "1")
    !haskey(style, "height") && orientation == "vertical" && (style["height"] = "20em")
    scp.dom = Node(:div, style = style, attributes = Dict("id" => id))
    layout = function (t)
        if orientation != "vertical"
            sld = t.scope
            sld = label !== nothing ?  flex_row(label, sld) : sld
            sld = readout ? vbox(vskip(3em), sld) : sld
            sld = div(sld, className = "field", style = Dict("flex-grow" => "1"))
        else
            sld = t.scope
            sld = readout ? hbox(hskip(6em), sld) : sld
            sld = label !== nothing ?  vbox(label, sld) : sld
            sld = div(sld, className = "field", style = Dict("flex-grow" => "1"))
        end
        sld
    end
    Widget{:rangeslider}(["index" => index], scope = scp, output = value, layout = layout)
end
