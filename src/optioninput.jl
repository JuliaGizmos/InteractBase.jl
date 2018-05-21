"""
```
dropdown(options::Associative;
         value = first(values(options)),
         label = nothing,
         multiple = false)
```

A dropdown menu whose item labels will be the keys of options.
If `multiple=true` the observable will hold an array containing the values
of all selected items
e.g. `dropdown(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`
"""
function dropdown(T::WidgetTheme, options::Associative;
    postprocess = identity,
    label = nothing,
    labeltype = T,
    multiple = false,
    selected = multiple ? valtype(options)[] : first(values(options)),
    class = "interact-widget",
    kwargs...)

    extra_attr = Dict{Symbol, Any}(kwargs)
    multiple && (extra_attr[:multiple] = true)

    (selected isa Observable) || (selected = Observable{Any}(selected))
    vmodel = (valtype(options) <: Number) ? "v-model.number" : "v-model"
    args = [Node(:option, key, attributes = Dict(:value=>val)) for (key, val) in options]
    s = gensym()
    attrDict = merge(
        Dict(Symbol(vmodel) => "value"),
        extra_attr
    )

    template = Node(:select, args..., className = class, attributes = attrDict) |> postprocess
    label != nothing && (template = vbox(template, wdglabel(labeltype, label)))
    ui = vue(template, ["value"=>selected]);
    primary_obs!(ui, "value")
    slap_design!(ui)
end

dropdown(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    dropdown(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

"""
```
radiobuttons(options::Associative;
             value::Union{T, Observable} = first(values(options)))
```

e.g. `radiobuttons(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`
"""
function radiobuttons(T::WidgetTheme, options::Associative; radiotype = T,
    selected = first(values(options)), outer = dom"form", kwargs...)

    (selected isa Observable) || (selected = Observable{Any}(selected))
    vmodel = isa(selected[], Number)  ? "v-model.number" : "v-model"

    s = gensym()
    btns = [radio(radiotype, s, key, val, vmodel; kwargs...) for (key, val) in options]

    template = outer(
        btns...
    )
    ui = vue(template, ["value" => selected])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

radiobuttons(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    radiobuttons(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

radio(T::WidgetTheme, s, key, val, vmodel; kwargs...) =
    dom"label"(dom"input[name = $s, type=radio, $vmodel=value, value=$val]"(), key)

"""
`togglebuttons(options::Associative; selected::Union{T, Observable})`

Creates a set of toggle buttons whose labels will be the keys of options.
"""
function togglebuttons(T::WidgetTheme, options::Associative; tag = :button, class = "interact-widget", outer = dom"div",
    activeclass = "active", selected = medianelement(1:length(options)), label = nothing, labeltype = T, kwargs...)

    jfunc = js"""function (num){
        return this.index = num;
    }
    """

    index = isa(selected, Observable) ? selected : Observable(selected)
    vals = collect(values(options))

    btns = [Node(tag,
                 label,
                 attributes=Dict("key" => idx,
                                 "v-on:click"=>"changeValue($idx)",
                                 "v-bind:class" => "['$class', {'$activeclass' : index == $idx}]")
                 ) for (idx, (label, val)) in enumerate(options)]

    template = outer(
        btns...
    )
    value = map(i -> vals[i], index)
    label != nothing && (template = hbox(wdglabel(labeltype, label), template))
    ui = vue(template, ["index" => index], methods = Dict(:changeValue => jfunc))
    primary_obs!(ui, value)
    slap_design!(ui)
end

function togglebuttons(T::WidgetTheme, vals; kwargs...)
    togglebuttons(T::WidgetTheme, OrderedDict(zip(string.(vals), vals)); kwargs...)
end

function tabs(T::WidgetTheme, options::Associative; tag = :li, kwargs...)
    togglebuttons(T::WidgetTheme, options; tag = tag, kwargs...)
end

function tabs(T::WidgetTheme, vals; kwargs...)
    tabs(T::WidgetTheme, OrderedDict(zip(vals, vals)); kwargs...)
end

function mask(options, values; key=Observable(""), display = "block")
    s = string(gensym())
    onjs(key, js"""
        function (k) {
            var options = document.getElementById($s).childNodes;
            for (var i=0; i < options.length; i++) {
                options[i].style.display = (options[i].getAttribute('key') ==  String(k)) ? $display : 'none';
            }
        }
    """)

    dom"div[id=$s]"(
        (dom"div[key=$option, style=display:none;]"(value) for (option, value) in zip(options, values))...
    )
end

mask(pairs::Associative; kwargs...) = mask(keys(pairs), values(pairs); kwargs...)
