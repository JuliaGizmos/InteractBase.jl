function dropdown(::WidgetTheme, options::Associative;
    postprocess = identity,
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
    ui = vue(template, ["value"=>selected]);
    primary_obs!(ui, "value")
    slap_design!(ui)
end

dropdown(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    dropdown(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

function radiobuttons(T::WidgetTheme, options::Associative; radiotype = T,
    postprocess = identity, selected = first(values(options)), outer = dom"form", kwargs...)

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

function togglebuttons(T::WidgetTheme, options::Associative; tag = :button, class = "interact-widget", outer = dom"div",
    postprocess = identity, activeclass = "active", selected = medianelement(1:length(options)), kwargs...)

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
