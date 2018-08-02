function _js_array(x::Associative; process=string, placeholder=nothing)
    v = OrderedDict[OrderedDict("key" => key, "val" => i, "id" => "id"*randstring()) for (i, (key, val)) in enumerate(x)]
    placeholder !== nothing && pushfirst!(v, OrderedDict("key" => placeholder, "val" => 0, "id" => "id"*randstring()))
    return v
end

function _js_array(x::AbstractArray; process=string, placeholder=nothing)
    v = OrderedDict[OrderedDict("key" => process(val), "val" => i, "id" => "id"*randstring()) for (i, val) in enumerate(x)]
    placeholder !== nothing && pushfirst!(v, OrderedDict("key" => placeholder, "val" => 0, "id" => "id"*randstring()))
    return v
end

function _js_array(o::Observable; process=string, placeholder=nothing)
    map(t -> _js_array(t; process=process, placeholder=placeholder), o)
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

Base.parent(d::Vals2Idxs) = d.vals

Base.get(d::Vals2Idxs, key, default = 0) = get(d.vals2idxs, key, default)
Base.get(d::Vals2Idxs, key::Integer, default = 0) = get(d.vals2idxs, key, default)
Base.get(d::Vals2Idxs{T}, key::AbstractArray{<:T}) where {T} = filter(t -> t!= 0, map(x -> get(d, x), key))

Base.getindex(d::Vals2Idxs, x::Int) = get(d.vals, x, nothing)

Base.size(d::Vals2Idxs) = size(d.vals)

function valueindexpair(value, vals2idxs, args...)
    f = x -> get(vals2idxs[], x)
    g = x -> getindex(vals2idxs[], x)
    ObservablePair(value, args..., f=f, g=g)
end

function initvalueindex(value, index, default, vals2idxs)
    if value === nothing
        value = (index === nothing) ? default[] : vals2idxs[][Observables._val(index)]
    end
    (value isa Observable) || (value = Observable{Any}(value))
    if index === nothing
        index = valueindexpair(value, vals2idxs).second
    else
        (index isa Observable) || (index = Observable{Any}(index))
        valueindexpair(value, vals2idxs, index)
    end
    return value, index
end

"""
```
dropdown(options::Associative;
         value = first(values(options)),
         label = nothing,
         multiple = false)
```

A dropdown menu whose item labels are the keys of options.
If `multiple=true` the observable will hold an array containing the values
of all selected items
e.g. `dropdown(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`dropdown(values::AbstractArray; kwargs...)`

`dropdown` with labels `string.(values)`
see `dropdown(options::Associative; ...)` for more details
"""
dropdown(T::WidgetTheme, options; kwargs...) =
    dropdown(T::WidgetTheme, Observable{Any}(options); kwargs...)

"""
```
dropdown(options::Observable;
         value = first(values(options[])),
         label = nothing,
         multiple = false)
```

A dropdown menu whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = dropdown(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
function dropdown(::WidgetTheme, options::Observable;
    attributes=PropDict(),
    placeholder = nothing,
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
    option_array = _js_array(options, placeholder=placeholder)
    disablePlaceholder =
        js"""
        function(option, item) {
            ko.applyBindingsToNode(option, {disable: item.val == 0}, item);
        }
        """

    attrDict = merge(
        Dict(Symbol("data-bind") => "options : options_js, $bind : index, optionsText: 'key', optionsValue: 'val', valueAllowUnset: true, optionsAfterRender: disablePlaceholder"),
        attributes
    )

    className = mergeclasses(getclass(:dropdown, multiple), className)
    template = Node(:select; className = className, attributes = attrDict, kwargs...)() |> div_select
    label != nothing && (template = vbox(label, template))
    ui = knockout(template, ["index" => valueindexpair(value, vals2idxs).second, "options_js" => option_array];
        methods = ["disablePlaceholder" => disablePlaceholder])
    slap_design!(ui)
    Widget{:dropdown}(["options"=>options, "index" => ui["index"]], scope = ui, output = value, layout = dom"div.field"∘Widgets.scope)
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
    ui = knockout(template, ["index" => valueindexpair(value, vals2idxs).second, "options_js" => option_array])
    (label != nothing) && (ui.dom = flex_row(wdglabel(label), ui.dom))
    slap_design!(ui)
    Widget{:radiobuttons}(["options"=>options, "index" => ui["index"]], scope = ui, output = value, layout = dom"div.field"∘Widgets.scope)
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

```
radiobuttons(options::Observable; kwargs...)
```

Radio buttons whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = radiobuttons(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
radiobuttons(T::WidgetTheme, vals; kwargs...) =
    multiselect(T, vals; kwargs...)

"""
```
checkboxes(options::Associative;
         value = first(values(options)))
```

A list of checkboxes whose item labels are the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `checkboxes(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`checkboxes(values::AbstractArray; kwargs...)`

`checkboxes` with labels `string.(values)`
see `checkboxes(options::Associative; ...)` for more details

```
checkboxes(options::Observable; kwargs...)
```

Checkboxes whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = checkboxes(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
checkboxes(T::WidgetTheme, options; kwargs...) =
    Widget{:checkboxes}(multiselect(T, options; typ="checkbox", kwargs...))

"""
```
toggles(options::Associative;
         value = first(values(options)))
```

A list of toggle switches whose item labels are the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `toggles(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`toggles(values::AbstractArray; kwargs...)`

`toggles` with labels `string.(values)`
see `toggles(options::Associative; ...)` for more details

```
toggles(options::Observable; kwargs...)
```

Toggles whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = toggles(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
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
            index = nothing, value = nothing,
            label = nothing, readout = false, vskip = 1em, kwargs...)

            value, index = initvalueindex(value, index, default, vals2idxs)

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
            ui = knockout(template, ["index" => index, "options_js" => option_array])
            slap_design!(ui)

            w = Widget{$(Expr(:quote, wdg))}(["options"=>options, "index" => ui["index"], "vals2idxs" => vals2idxs];
                scope = ui, output = value, layout = dom"div.field"∘Widgets.scope)
            if readout
                content = map(vals2idxs) do v
                    nodes = (Node(:div, v[i],  attributes = Dict("data-bind" => "visible: index() == $i")) for i in 1:length(v))
                    knockout(Node(:div, nodes...), ["index" => index])
                end
                w.display = content
                w.layout = t -> vbox(dom"div.field"(Widgets.scope(t)), CSSUtil.vskip(vskip), t.display)
            end
            w
        end
    end
end

"""
`togglebuttons(options::Associative; value::Union{T, Observable})`

Creates a set of toggle buttons whose labels are the keys of options.

`togglebuttons(values::AbstractArray; kwargs...)`

`togglebuttons` with labels `string.(values)`
see `togglebuttons(options::Associative; ...)` for more details

```
togglebuttons(options::Observable; kwargs...)
```

Togglebuttons whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = togglebuttons(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
function togglebuttons end

"""
`tabs(options::Associative; value::Union{T, Observable})`

Creates a set of tabs whose labels are the keys of options. The label can be a link.

`tabs(values::AbstractArray; kwargs...)`

`tabs` with labels `values`
see `tabs(options::Associative; ...)` for more details

```
tabs(options::Observable; kwargs...)
```

Tabs whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = tabs(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
function tabs end

@deprecate tabulator(T::WidgetTheme, keys, vals; kwargs...) tabulator(T, OrderedDict(zip(keys, vals)); kwargs...)

"""
`tabulator(options::Associative; index = 1, key = nothing)`

Creates a set of toggle buttons whose labels are the keys of options. Displays the value of the selected option underneath.
Use `index::Int` to select which should be the index of the initial option, or `key::String`.
The output is the selected `index`. Use `index=0` to not have any selected option.

## Examples

```julia
tabulator(OrderedDict("plot" => plot(rand10), "scatter" => scatter(rand(10))), index = 1)
tabulator(OrderedDict("plot" => plot(rand10), "scatter" => scatter(rand(10))), key = "plot")
```

`tabulator(values::AbstractArray; kwargs...)`

`tabulator` with labels `values`
see `tabulator(options::Associative; ...)` for more details

```
tabulator(options::Observable; kwargs...)
```

Tabulator whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = tabulator(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
function tabulator(T::WidgetTheme, options; vskip = 1em, value = 1, index = value, key = nothing,  kwargs...)
    index isa Observable || (index = Observable{Any}(index))
    key isa Observable || (key = Observable{Any}(key))
    options isa Observable || (options = Observable{Any}(options))

    pair = valueindexpair(key, map(Vals2Idxs∘collect∘keys, options), index)
    key[] == nothing ? key[] = pair.g(index[]) : index[] = pair.f(key[])

    tb = togglebuttons(T, options; index = index, readout = true, kwargs...)
    buttons = dom"div.filed"(Widgets.scope(tb))
    layout = t -> vbox(t[:buttons], CSSUtil.vskip(vskip), t[:content])
    Widget{:tabulator}(["key" => key, "buttons" => buttons, "content" => tb.display], output = index, layout = layout)
end
