function dropdown(::WidgetTheme, options::Associative;
    postprocess = identity,
    multiple = false,
    selected = multiple ? valtype(options)[] : first(values(options)),
    kwargs...)

    extra_attr = Dict{Symbol, Any}(kwargs)
    multiple && (extra_attr[:multiple] = true)

    (selected isa Observable) || (selected = Observable{Any}(selected))
    vmodel = (isa(selected[], Number) || isa(selected[], AbstractArray{<:Number})) ? "v-model.number" : "v-model"
    args = [Node(:option, key, attributes = Dict(:value=>val)) for (key, val) in options]
    s = gensym()
    attrDict = merge(
        Dict(Symbol(vmodel) => "value"),
        extra_attr
    )

    template = Node(:select, args..., attributes = attrDict) |> postprocess
    ui = vue(template, ["value"=>selected]);
    primary_obs!(ui, "value")
    slap_design!(ui)
end

dropdown(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    dropdown(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

function radiobuttons(T::WidgetTheme, options::Associative;
    postprocess = identity, selected = first(values(options)), kwargs...)

    (selected isa Observable) || (selected = Observable{Any}(selected))
    vmodel = isa(selected[], Number)  ? "v-model.number" : "v-model"

    s = gensym()
    btns = [(dom"input[name = $s, type=radio, $vmodel=value, value=$val]"(),
        dom"label"(key), dom"br"()) for (key, val) in options]

    template = dom"form"(
        Iterators.flatten(btns)...
    )
    ui = vue(template, ["value" => selected])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

radiobuttons(T::WidgetTheme, vals::AbstractArray; kwargs...) =
    radiobuttons(T, OrderedDict(zip(string.(vals), vals)); kwargs...)

function togglebuttons(T::WidgetTheme, options::Associative; tag = :button, class = "interact-widget", outer = dom"div",
    postprocess = identity, activeclass = "active", kwargs...)

    jfunc = js"""function (ev, num){
        this.index = num;
        return this.value = ev;
    }
    """

    value = Observable("")

    btns = [Node(tag,
                 label,
                 attributes=Dict("key" => idx,
                                 "v-on:click"=>"changeValue('$val', $idx)",
                                 "v-bind:class" => "['$class', {'$activeclass' : index == $idx}]")
                 ) for (idx, (label, val)) in enumerate(options)]

    template = outer(
        btns...
    )
    ui = vue(template, ["value" => value, "index" => Observable(0)], methods = Dict(:changeValue => jfunc))
    primary_obs!(ui, "value")
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
                options[i].style.display = (options[i].getAttribute('key') == k) ? $display : 'none';
            }
        }
    """)

    dom"div[id=$s]"(
        (dom"div[key=$option, style=display:none;]"(value) for (option, value) in zip(options, values))...
    )
end
