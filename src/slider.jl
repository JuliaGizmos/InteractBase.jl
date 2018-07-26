toFloatArray(x::Number) = [Float64(x)]
toFloatArray(x::AbstractArray) = map(Float64, x)

function rangeslider(value; orientation = "horizontal")
    value isa Observable || (value = Observable{Any}(value))
    scp = Scope(imports = [nouislider_min_js, nouislider_min_css])
    setobservable!(scp, "value", value)
    # value_js = Observable(scp, "value_js", value[])
    connect = (value[] isa AbstractArray && length(value[]) <= 1) ? js"true" : js"[true, false]"

    id = "slider"*randstring()
    start = JSExpr.@js $value[]
    updateValue = JSExpr.@js function updateValue(values, handle, unencoded, tap, positions)
        $value[] = Array.isArray($value[]) ? unencoded : unencoded[0]
    end

    onimport(scp, js"""
        function (noUiSlider) {
            $updateValue
            var slider = document.getElementById($id);
            noUiSlider.create(slider, {
            	start: $start,
                step: 1,
                connect: $connect,
                orientation: $orientation,
            	range: {
            		'min': 0,
            		'max': 100
            	},})

            slider.noUiSlider.on("update", updateValue);
        }
        """)
    scp.dom = Node(:div, style = Dict("flex-grow" => "1"), attributes = Dict("id" => id))
    scp
end
