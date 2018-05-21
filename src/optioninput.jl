function dropdown(::WidgetTheme, options::Associative;
    postprocess = identity,
    multiple = false,
    selected = multiple ? valtype(options)[] : first(values(options)),
    class = "interact-widget",
    kwargs...)

    extra_attr = Dict{Symbol, Any}(kwargs)
    multiple && (extra_attr[:multiple] = true)
    vals = collect(values(options))

    (selected isa Observable) || (selected = Observable{Any}(selected))
    args = [Node(:option, key, attributes = Dict(:index=>idx)) for (idx, (key, val)) in enumerate(options)]
    s = gensym()
    attrDict = merge(
        Dict(Symbol("v-model.number") => "index"),
        extra_attr
    )
    value = map(i -> vals[i], selected)
    template = Node(:select, args..., className = class, attributes = attrDict) |> postprocess
    ui = vue(template, ["index"=>selected]);
    primary_obs!(ui, value)
    slap_design!(ui)
end

dropdown(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    dropdown(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

function _radiobuttons(T::WidgetTheme, options::Associative;
    postprocess = identity, selected = first(values(options)), outer = dom"form", kwargs...)

    (selected isa Observable) || (selected = Observable{Any}(selected))
    vmodel = isa(selected[], Number)  ? "v-model.number" : "v-model"

    s = gensym()
    btns = [radio(T, s, key, val, vmodel; kwargs...) for (key, val) in options]

    template = outer(
        btns...
    )
    ui = vue(template, ["value" => selected])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

radiobuttons(T::WidgetTheme, options::Associative; kwargs...) =
    _radiobuttons(T, options; kwargs...)

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
