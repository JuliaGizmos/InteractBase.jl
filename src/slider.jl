_length(v::AbstractArray) = length(v)
_length(::Any) = 1
_map(f, v::AbstractArray) = map(f, v)
_map(f, v) = f(v)

function format(x)
    io = IOBuffer()
    show(IOContext(io, :compact => true), x)
    String(take!(io))
end

"""
```
function slider(vals::AbstractArray;
                value=medianelement(vals),
                label=nothing, readout=true, kwargs...)
```

Creates a slider widget which can take on the values in `vals`, and updates
observable `value` when the slider is changed. Pass a vector to `value` with two values if you want to
select a range.
"""
function slider(vals::AbstractArray, formatted_vals = format.(vec(vals)); value = medianelement(vals), kwargs...)

    T = Observables._val(value) isa Vector ? Vector{eltype(vals)} : eltype(vals)
    value isa AbstractObservable || (value = Observable{T}(value))

    vals = vec(vals)
    indices = axes(vals)[1]
    f = x -> _map(t -> searchsortedfirst(vals, t), x)
    g = x -> vals[Int.(x)]
    index = ObservablePair(value, f = f, g = g).second
    wdg = slider(indices, formatted_vals; value = index, kwargs...)
    Widget(wdg, output = value)
end

function slider(vals::AbstractRange{<:Integer}, formatted_vals = format.(vals);
    style = Dict(), label = nothing, value = medianelement(vals), orientation = "horizontal", readout = true,
    kwargs...)

    T = Observables._val(value) isa Vector ? Vector{eltype(vals)} : eltype(vals)
    value isa AbstractObservable || (value = Observable{T}(value))
    orientation = string(orientation)

    index = value

    preprocess = T<:Vector ? js"unencoded.map(Math.round)" : js"Math.round(unencoded[0])"

    scp = Scope(imports = [nouislider_min_js, nouislider_min_css])
    setobservable!(scp, "index", index)
    fromJS = Observable(scp, "fromJS", false)
    changes = Observable(scp, "changes", 0)
    connect = _length(index[]) > 1 ? js"true" : js"[true, false]"
    min, max = extrema(vals)
    s = step(vals)

    id = "slider"*randstring()
    start = JSExpr.@js $index[]
    updateValue = JSExpr.@js function updateValue(values, handle, unencoded, tap, positions)
        $fromJS[] = true
        $index[] = $preprocess
    end
    updateCount = JSExpr.@js function updateCount(values, handle, unencoded, tap, positions)
        $changes[] = $changes[]+1
    end
    tooltips = JSString("[" * join(fill(readout, _length(value[])), ", ") * "]")

    onimport(scp, js"""
        function (noUiSlider) {
            var vals = JSON.parse($(JSON.json(formatted_vals)));
            $updateValue
            $updateCount
            var slider = document.getElementById($id);
            noUiSlider.create(slider, {
            	start: $start,
                step: $s,
                tooltips: $tooltips,
                connect: $connect,
                orientation: $orientation,
                format: {
                to: function ( value ) {
                    var ind = Math.round((value-$min)/$s);
                    return ind + 1 > vals.length ? vals[vals.length - 1] : vals[ind];
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
            slider.noUiSlider.on("change", updateCount);
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
    scp.dom = node(:div, style = style, attributes = Dict("id" => id))
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
    Widget{:slider}(["index" => index, "changes" => changes];
        scope = scp, output = value, layout = layout)
end

"""
```
function rangepicker(vals::AbstractArray;
                value=[extrema(vals)...],
                label=nothing, readout=true, kwargs...)
```

A multihandle slider with a set of spinboxes, one per handle.
"""
function rangepicker(vals::AbstractRange{S}; value = [extrema(vals)...], readout = false) where {S}
    T = Observables._val(value) isa Vector ? Vector{eltype(vals)} : eltype(vals)
    value isa AbstractObservable || (value = Observable{T}(value))
    wdg = Widget{:rangepicker}(output = value)
    if !(T<:Vector)
        wdg["input"] = input(S, vals, value=value)
    else
        function newinput(i)
            f = t -> t[i]
            g = t -> (s = copy(value[]); s[i] = t; s)
            new_val = ObservablePair(value, f=f, g=g).second
            input(S, vals, value = new_val)
        end

        for i in eachindex(value[])
            wdg["input$i"] = newinput(i)
        end
    end
    inputs = t -> (val for (key, val) in components(t) if occursin(r"slider|input", string(key)))
    wdg.layout = t -> div(inputs(t)...)
    wdg["slider"] = slider(vals, value = value, readout = readout)
    wdg["changes"] = map(+, (val["changes"] for val in inputs(wdg))...)
    return wdg
end

@deprecate rangeslider slider
