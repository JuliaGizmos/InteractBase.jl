_length(v::AbstractArray) = length(v)
_length(::Any) = 1

function rangeslider(vals::Range{<:Integer}; value = medianelement(vals), orientation = "horizontal", readout = true)

    T = Observables._val(value) isa Vector ? Vector{Int} : Int
    value isa Observable || (value = Observable{T}(value))
    preprocess = T<:Vector ? js"values.map(parseFloat)" : js"parseFloat(values[0])"
    scp = Scope(imports = [nouislider_min_js, nouislider_min_css])
    setobservable!(scp, "value", value)
    connect = _length(value[]) > 1 ? js"true" : js"[true, false]"
    min, max = extrema(vals)
    s = step(vals)
    id = "slider"*randstring()
    start = JSExpr.@js $value[]
    updateValue = JSExpr.@js function updateValue(values, handle, unencoded, tap, positions)
        $value[] = $preprocess
    end
    tooltips = JSString("[" * join(fill(readout, _length(value[])), ", ") * "]")

    onimport(scp, js"""
        function (noUiSlider) {
            $updateValue
            var slider = document.getElementById($id);
            noUiSlider.create(slider, {
            	start: $start,
                step: $s,
                tooltips: $tooltips,
                connect: $connect,
                orientation: $orientation,
                format: {
                to: function ( value ) {
                    return Math.round(value)+'';
                },
                from: function ( value ) {
                    return value;
                  }
                },
            	range: {
            		'min': $min,
            		'max': $max
            	},})

            slider.noUiSlider.on("update", updateValue);
        }
        """)
    scp.dom = Node(:div, style = Dict("flex-grow" => "1"), attributes = Dict("id" => id))
    scp
end
