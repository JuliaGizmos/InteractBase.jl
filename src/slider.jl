function rangeslider(value; orientation = "horizontal")
    value isa Observable || (value = Observable{Any}(value))
    connect = (value[] isa Number) || (length(value[]) <= 1) ? js"[true, false]" : js"true"
    id = "slider"*randstring()
    scp = Scope(imports = [nouislider_min_js, nouislider_min_css])
    setobservable!(scp, "value", value)
    start = JSExpr.@js $value[]
    onimport(scp, js"""
        function (noUiSlider) {
            var slider = document.getElementById($id);
            noUiSlider.create(slider, {
            	start: $start,
                connect: $connect,
                orientation: $orientation,
            	range: {
            		'min': 0,
            		'max': 100
            	},})
        }
        """)
    scp.dom = Node(:div, style = Dict("flex-grow" => "1"), attributes = Dict("id" => id))
    scp
end
