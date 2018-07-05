function _js_array(x::Associative; process=string)
    [OrderedDict("key" => key, "val" => i, "id" => "id"*randstring()) for (i, (key, val)) in enumerate(x)]
end

function _js_array(x::AbstractArray; process=string)
    [OrderedDict("key" => process(val), "val" => i, "id" => "id"*randstring()) for (i, val) in enumerate(x)]
end

function _js_array(o::Observable; process=string)
    map(t -> _js_array(t; process=process), o)
end

struct Vals2Idxs{T} <: AbstractVector{T}
    vals::Vector{T}
    vals2idxs::Dict{T, Int}
    function Vals2Idxs(v::AbstractArray{T}) where {T}
        vals = convert(Vector{T}, v)
        idxs = 1:length(vals)
        vals2idxs = Dict{T, Int}(zip(vals, idxs))
        new{T}(vals, vals2idxs)
    end
end

Vals2Idxs(v::Associative) = Vals2Idxs(collect(values(v)))

Base.get(d::Vals2Idxs, key) = d.vals2idxs[key]
Base.get(d::Vals2Idxs, key::AbstractArray) = map(x -> d.vals2idxs[x], key)

Base.getindex(d::Vals2Idxs, x::Int) = getindex(d.vals, x)

Base.size(d::Vals2Idxs) = size(d.vals)

function valueindexpair(value, vals2idxs)
    f = x -> get(vals2idxs[], x)
    g = x -> getindex(vals2idxs[], x)
    ObservablePair(value, f=f, g=g)
end

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

`dropdown(values::AbstractArray; kwargs...)`

`dropdown` with labels `string.(values)`
see `dropdown(options::Associative; ...)` for more details
"""
dropdown(T::WidgetTheme, options; kwargs...) =
    dropdown(T::WidgetTheme, Observable{Any}(options); kwargs...)

function dropdown(::WidgetTheme, options::Observable;
    attributes=PropDict(),
    label = nothing,
    multiple = false,
    vals2idxs = map(Vals2Idxs, options),
    default = multiple ? map(getindex∘eltype, vals2idxs) : map(first, vals2idxs),
    value = default[],
    className = "",
    style = PropDict(),
    div_select = dom"div.select",
    kwargs...)

    multiple && (attributes[:multiple] = true)

    (value isa Observable) || (value = Observable{Any}(value))
    connect!(default, value)

    bind = multiple ? "selectedOptions" : "value"
    option_array = _js_array(options)
    s = gensym()
    attrDict = merge(
        Dict(Symbol("data-bind") => "options : options_js, $bind : index, optionsText: 'key', optionsValue: 'val'"),
        attributes
    )

    className = mergeclasses(getclass(:dropdown), className)
    template = Node(:select; className = className, attributes = attrDict, kwargs...)() |> div_select
    label != nothing && (template = vbox(template, wdglabel(label)))
    ui = knockout(template, ["index" => valueindexpair(value, vals2idxs), "options_js" => option_array]);
    slap_design!(ui)
    Widget{:dropdown}(["options"=>options, "index" => ui["index"]], scope = ui, output = value, layout = t -> dom"div.field"(t.scope))
end

multiselect(T::WidgetTheme, options; kwargs...) =
    multiselect(T, Observable{Any}(options); kwargs...)

function multiselect(T::WidgetTheme, options::Observable;
    label = nothing, typ="radio", wdgtyp=typ,
    vals2idxs = map(Vals2Idxs, options),
    default = (typ != "radio") ? map(getindex∘eltype, vals2idxs) : map(first, vals2idxs),
    value = default[], kwargs...)

    (value isa Observable) || (value = Observable{Any}(value))
    connect!(default, value)

    s = gensym()
    option_array = _js_array(options)
    entry = InteractBase.entry(s; typ=typ, wdgtyp=wdgtyp, kwargs...)
    (entry isa Tuple )|| (entry = (entry,))
    template = Node(:div, className=getclass(:radiobuttons), attributes = "data-bind" => "foreach : options_js")(
        entry...
    )
    ui = knockout(template, ["index" => valueindexpair(value, vals2idxs), "options_js" => option_array])
    (label != nothing) && (scope(ui).dom = flex_row(wdglabel(label), scope(ui).dom))
    slap_design!(ui)
    Widget{:radiobuttons}(["options"=>options, "index" => ui["index"]], scope = ui, output = value, layout = t -> dom"div.field"(t.scope))
end

function entry(T::WidgetTheme, s; className="", typ="radio", wdgtyp=typ, stack=(typ!="radio"), kwargs...)
    className = mergeclasses(getclass(:input, wdgtyp), className)
    f = stack ? Node(:div, className="field") : tuple
    f(
        Node(:input, className = className, attributes = Dict("name" => s, "type" => typ, "data-bind" => "checked : \$root.index, checkedValue: val, attr : {id : id}"))(),
        Node(:label, attributes = Dict("data-bind" => "text : key, attr : {for : id}"))
    )
end

"""
```
radiobuttons(options::Associative;
             value::Union{T, Observable} = first(values(options)))
```

e.g. `radiobuttons(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`radiobuttons(values::AbstractArray; kwargs...)`

`radiobuttons` with labels `string.(values)`
see `radiobuttons(options::Associative; ...)` for more details
"""
radiobuttons(T::WidgetTheme, vals; kwargs...) =
    multiselect(T, vals; kwargs...)

"""
```
checkboxes(options::Associative;
         value = first(values(options)))
```

A list of checkboxes whose item labels will be the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `checkboxes(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`checkboxes(values::AbstractArray; kwargs...)`

`checkboxes` with labels `string.(values)`
see `checkboxes(options::Associative; ...)` for more details
"""
checkboxes(T::WidgetTheme, options; kwargs...) =
    Widget{:checkboxes}(multiselect(T, options; typ="checkbox", kwargs...))

"""
```
toggles(options::Associative;
         value = first(values(options)))
```

A list of toggle switches whose item labels will be the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `toggles(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`toggles(values::AbstractArray; kwargs...)`

`toggles` with labels `string.(values)`
see `toggles(options::Associative; ...)` for more details
"""
toggles(T::WidgetTheme, options; kwargs...) =
    Widget{:toggles}(multiselect(T, options; typ="checkbox", wdgtyp="toggle", kwargs...))

for (wdg, tag, singlewdg, div, process) in zip([:togglebuttons, :tabs], [:button, :li], [:button, :tab], [:div, :ul], [:string, :identity])
    @eval begin
        $wdg(T::WidgetTheme, options; kwargs...) = $wdg(T::WidgetTheme, Observable(options); kwargs...)

        function $wdg(T::WidgetTheme, options::Observable; tag = $(Expr(:quote, tag)),
            className = getclass($(Expr(:quote, singlewdg)), "fullwidth"),
            activeclass = getclass($(Expr(:quote, singlewdg)), "active"),
            vals2idxs = map(Vals2Idxs, options),
            default = map(medianelement, vals2idxs),
            value = default[], label = nothing, kwargs...)

            (value isa Observable) || (value = Observable{Any}(value))
            connect!(default, value)

            className = mergeclasses(getclass($(Expr(:quote, singlewdg))), className)

            btn = Node(tag,
                Node(:label, attributes = Dict("data-bind" => "text : key")),
                attributes=Dict("data-bind"=>
                "click: function () {\$root.index(val)}, css: {'$activeclass' : \$root.index() == val, '$className' : true}"),
            )
            option_array = _js_array(options; process = $process)
            template = Node($(Expr(:quote, div)), className = getclass($(Expr(:quote, wdg))), attributes = "data-bind" => "foreach : options_js")(
                btn
            )

            label != nothing && (template = flex_row(wdglabel(label), template))
            ui = knockout(template, ["index" => valueindexpair(value, vals2idxs), "options_js" => option_array])
            slap_design!(ui)
            Widget{$(Expr(:quote, wdg))}(["options"=>options, "index" => ui["index"]], scope = ui, output = value, layout = t -> dom"div.field"(t.scope))
        end
    end
end

"""
`togglebuttons(options::Associative; value::Union{T, Observable})`

Creates a set of toggle buttons whose labels will be the keys of options.

`togglebuttons(values::AbstractArray; kwargs...)`

`togglebuttons` with labels `string.(values)`
see `togglebuttons(options::Associative; ...)` for more details
"""
function togglebuttons end

@deprecate tabulator(T::WidgetTheme, keys, vals; kwargs...) tabulator(T, OrderedDict(zip(keys, vals)); kwargs...)

function tabulator(T::WidgetTheme, options; vskip = 1em, value = 1, kwargs...)
    (value isa Observable) || (value = Observable(value))
    buttons = togglebuttons(T, options; kwargs...)
    buttons["index"][] != value[] && (buttons["index"][] = value[])
    ObservablePair(value, buttons["index"])
    layout = t -> vbox(t[:buttons], CSSUtil.vskip(vskip), t[:content])
    Widget{:tabulator}(["buttons" => buttons, "content" => observe(buttons)], output = value, layout = layout)
end
