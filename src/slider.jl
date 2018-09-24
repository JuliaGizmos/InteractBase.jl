_length(v::AbstractArray) = length(v)
_length(::Any) = 1
_map(f, v::AbstractArray) = map(f, v)
_map(f, v) = f(v)

function format(x)
    io = IOBuffer()
    show(IOContext(io, :compact => true), x)
    String(take!(io))
end

for func in [:rangeslider, :slider]
    @eval begin
        function $func(WT::WidgetTheme, vals::AbstractArray, formatted_vals = format.(vec(vals)); value = medianelement(vals), kwargs...)

            T = Observables._val(value) isa Vector ? Vector{eltype(vals)} : eltype(vals)
            value isa AbstractObservable || (value = Observable{T}(value))

            vals = vec(vals)
            indices = axes(vals)[1]
            f = x -> _map(t -> searchsortedfirst(vals, t), x)
            g = x -> vals[Int.(x)]
            index = ObservablePair(value, f = f, g = g).second
            wdg = Widget($func(WT, indices, formatted_vals; value = index, kwargs...), output = value)
            wdg["value"] = value
            wdg
        end
    end
end

"""
```
function slider(vals::AbstractArray;
                value=medianelement(vals),
                label=nothing, readout=true, kwargs...)
```

Creates a slider widget which can take on the values in `vals`, and updates
observable `value` when the slider is changed.
"""
function slider(::WidgetTheme, vals::AbstractRange{<:Integer};
    bindto="value", text=bindto, className=getclass(:input, "range", "fullwidth"),
    readout=true, label=nothing, value=medianelement(vals), orientation = "horizontal", attributes = Dict(), kwargs...)

    orientation = string(orientation)
    attributes = merge(attributes, Dict("orient" => orientation))
    (value isa AbstractObservable) || (value = convert(eltype(vals), value))
    ui = input(value; bindto=bindto, attributes=attributes,
        typ="range", min=minimum(vals), max=maximum(vals), step=step(vals), className=className, kwargs...)
    if (label != nothing) || readout
        if orientation != "vertical"
            Widgets.scope(ui).dom = readout ?
                flex_row(wdglabel(label), Widgets.scope(ui).dom, node(:p, attributes = Dict("data-bind" => "text: $text"))) :
                flex_row(wdglabel(label), Widgets.scope(ui).dom)
        else
            readout && (label = vbox(label, node(:p, attributes = Dict("data-bind" => "text: $text"))))
            Widgets.scope(ui).dom  = hbox(wdglabel(label), dom"div[style=flex-shrink:1]"(Widgets.scope(ui).dom))
        end
    end
    Widget{:slider}(ui)
end

function slider(T::WidgetTheme, vals::Base.OneTo, formatted_vals;
    bindto="index", text=bindto, value=medianelement(vals), kwargs...)

    (value isa AbstractObservable) || (value = Observable{Int}(value))
    (formatted_vals isa AbstractObservable) || (formatted_vals = Observable{Any}(formatted_vals))
    formatted_value = Observable{eltype(formatted_vals[])}(formatted_vals[][value[]])
    s = slider(T, vals; extra_obs=["formatted_vals" => formatted_vals, "formatted_value" => formatted_value],
        bindto="index", text="formatted_value", value=value, kwargs...)
    s["value"] = value
    onjs(value, JSExpr.@js function (val)
        $formatted_value[] = $formatted_vals[][$value[]-1]
    end)
    s
end

"""
```
function rangeslider(vals::AbstractArray;
                value=medianelement(vals),
                label=nothing, readout=true, kwargs...)
```

Creates a slider widget which can take on the values in `vals` and accepts several "handles".
Pass a vector to `value` with two values if you want to select a range.
"""
function rangeslider(::WidgetTheme, vals::AbstractRange{<:Integer}, formatted_vals = format.(vals);
    style = Dict(), label = nothing, value = medianelement(vals), orientation = "horizontal", readout = true)

    T = Observables._val(value) isa Vector ? Vector{eltype(vals)} : eltype(vals)
    value isa AbstractObservable || (value = Observable{T}(value))

    index = value
    orientation = string(orientation)
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

    class = getclass(:input, "rangeslider", orientation)
    style = Dict{String, Any}(string(key) => val for (key, val) in style)

    haskey(style, "flex-grow") || (style["flex-grow"] = "1")
    !haskey(style, "height") && orientation == "vertical" && (style["height"] = "20em")
    scp.dom = node(:div, style = style, attributes = Dict("id" => id))
    layout = function (t)
        if orientation != "vertical"
            sld = t.scope
            sld = label !== nothing ?  flex_row(label, sld) : sld
            sld = readout ? vbox(vskip(3em), sld) : sld
            sld = div(sld, className = "field rangeslider rangeslider-horizontal")
        else
            sld = t.scope
            sld = readout ? hbox(hskip(6em), sld) : sld
            sld = label !== nothing ?  vbox(label, sld) : sld
            sld = div(sld, className = "field rangeslider rangeslider-vertical")
        end
        sld
    end
    Widget{:rangeslider}(["index" => index, "changes" => changes];
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
function rangepicker(::WidgetTheme, vals::AbstractRange{S}; value = [extrema(vals)...], readout = false) where {S}
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
    wdg["slider"] = rangeslider(vals, value = value, readout = readout)
    wdg["changes"] = map(+, (val["changes"] for val in inputs(wdg))...)
    return wdg
end
