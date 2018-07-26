toFloatArray(x::Number) = [Float64(x)]
toFloatArray(x::AbstractArray) = map(Float64, x)

function rangeslider(vals::Range{<:Integer}; value = medianelement(vals), orientation = "horizontal")

    T = Observables._val(value) isa Vector ? Vector{Int} : Vector
    value isa Observable || (value = Observable{T}(value))
    preprocess = T<:Vector ? js"unencoded.map(Math.round)" : js"Math.round(unencoded[0])"
    scp = Scope(imports = [nouislider_min_js, nouislider_min_css])
    setobservable!(scp, "value", value)
    connect = (value[] isa AbstractArray && length(value[]) > 1) ? js"true" : js"[true, false]"
    min, max = extrema(vals)
    s = step(vals)
    id = "slider"*randstring()
    start = JSExpr.@js $value[]
    updateValue = JSExpr.@js function updateValue(values, handle, unencoded, tap, positions)
        $value[] = $preprocess
    end

    onimport(scp, js"""
        function (noUiSlider) {
            $updateValue
            var slider = document.getElementById($id);
            noUiSlider.create(slider, {
            	start: $start,
                step: $s,
                connect: $connect,
                orientation: $orientation,
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
