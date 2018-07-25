_format(value::Number) = string(value)
function _format(values::AbstractArray{<:Number})
    str = join(map(_format, values), ", ")
    "[$str]"
end

function rangeslider(value)
    js_val = JSExpr.JSString(_format(value))
    connect = (value isa Number) || (length(value) <= 1) ? js"[true, false]" : js"true"
    id = "slider"*randstring()
    scp = Scope(imports = [nouislider_min_js, nouislider_min_css])
    onimport(scp, js"""
        function (noUiSlider) {
            var slider = document.getElementById($id);
            noUiSlider.create(slider, {
            	start: $js_val,
                connect: $connect,
            	range: {
            		'min': 0,
            		'max': 100
            	},})
        }
        """)
    scp.dom = Node(:div, attributes = Dict("id" => id))
    scp
end
