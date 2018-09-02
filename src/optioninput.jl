function _js_array(x::AbstractDict; process=string, placeholder=nothing)
    v = OrderedDict[OrderedDict("key" => key, "val" => i, "id" => "id"*randstring()) for (i, (key, val)) in enumerate(x)]
    placeholder !== nothing && pushfirst!(v, OrderedDict("key" => placeholder, "val" => 0, "id" => "id"*randstring()))
    return v
end

function _js_array(x::AbstractArray; process=string, placeholder=nothing)
    v = OrderedDict[OrderedDict("key" => process(val), "val" => i, "id" => "id"*randstring()) for (i, val) in enumerate(x)]
    placeholder !== nothing && pushfirst!(v, OrderedDict("key" => placeholder, "val" => 0, "id" => "id"*randstring()))
    return v
end

function _js_array(o::AbstractObservable; process=string, placeholder=nothing)
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

Vals2Idxs(v::AbstractDict) = Vals2Idxs(collect(values(v)))

Base.parent(d::Vals2Idxs) = d.vals

Base.get(d::Vals2Idxs, key, default = 0) = get(d.vals2idxs, key, default)
Base.get(d::Vals2Idxs, key::Integer, default = 0) = get(d.vals2idxs, key, default)
getmany(d::Vals2Idxs{T}, key::AbstractArray{<:T}, default = 0) where {T} =
    filter(t -> t!= 0, map(x -> get(d, x), key))

Base.getindex(d::Vals2Idxs, x::Int) = get(d.vals, x, nothing)

Base.size(d::Vals2Idxs) = size(d.vals)

function valueindexpair(value, vals2idxs, args...; multiple = false, rev = false)
    _get = multiple ? getmany : get
    f = x -> _get(vals2idxs[], x)
    g = x -> getindex(vals2idxs[], x)
    p = ObservablePair(value, args..., f=f, g=g)
    on(vals2idxs) do x
        p.excluded[rev+1](p[rev+1][])
    end
    p
end

function initvalueindex(value, index, vals2idxs;
    multiple = false, default = multiple ? eltype(vals2idxs[])[] : first(vals2idxs[]), rev = false)

    if value === Some(nothing)
        value = (index === nothing) ? default : vals2idxs[][Observables._val(index)]
    end
    (value isa AbstractObservable) || (value = Observable{Any}(value))
    if index === nothing
        p = valueindexpair(value, vals2idxs; multiple = multiple, rev = rev)
        index = p.second
    else
        (index isa AbstractObservable) || (index = Observable{Any}(index))
        p = valueindexpair(value, vals2idxs, index; multiple = multiple, rev = rev)
    end
    return p
end

"""
```
dropdown(options::AbstractDict;
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
see `dropdown(options::AbstractDict; ...)` for more details
"""
dropdown(T::WidgetTheme, options; kwargs...) =
    dropdown(T::WidgetTheme, Observable{Any}(options); kwargs...)

"""
```
dropdown(options::AbstractObservable;
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
function dropdown(::WidgetTheme, options::AbstractObservable;
    attributes=PropDict(),
    placeholder = nothing,
    label = nothing,
    multiple = false,
    value = Some(nothing),
    index = nothing,
    className = "",
    style = PropDict(),
    div_select = nothing,
    kwargs...)

    div_select !== nothing && warn("`div_select` keyword is deprecated", once=true)
    multiple && (attributes[:multiple] = true)
    vals2idxs = map(Vals2Idxs, options)
    p = initvalueindex(value, index, vals2idxs, multiple = multiple)
    value, index = p.first, p.second

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
    div_select === nothing && (div_select = node(:div, className = className))
    template = node(:select; attributes = attrDict, kwargs...)() |> div_select
    label != nothing && (template = vbox(label, template))
    ui = knockout(template, ["index" => index, "options_js" => option_array];
        methods = ["disablePlaceholder" => disablePlaceholder])
    slap_design!(ui)
    Widget{:dropdown}(["options"=>options, "index" => ui["index"]], scope = ui, output = value, layout = dom"div.field"∘Widgets.scope)
end

multiselect(T::WidgetTheme, options; kwargs...) =
    multiselect(T, Observable{Any}(options); kwargs...)

function multiselect(T::WidgetTheme, options::AbstractObservable; container=node(:div, className=:field), wrap=identity,
    label = nothing, typ="radio", wdgtyp=typ, stack=true, skip=1em, hskip=skip, vskip=skip,
    value = Some(nothing), index = nothing, kwargs...)
    attributes = merge(get(props(container), :attributes, Dict()), Dict("data-bind" => "foreach : options_js"))
    vals2idxs = map(Vals2Idxs, options)
    p = initvalueindex(value, index, vals2idxs, multiple = (typ != "radio"))
    value, index = p.first, p.second

    s = gensym()
    option_array = _js_array(options)
    entry = wrap(InteractBase.entry(s; typ=typ, wdgtyp=wdgtyp, stack=stack, kwargs...))
    (entry isa Tuple )|| (entry = (entry,))
    template = container(attributes = attributes)(
        entry...
    )
    ui = knockout(template, ["index" => index, "options_js" => option_array])
    if (label != nothing)
        ui.dom = stack ? vbox(label, CSSUtil.vskip(vskip), ui.dom) : hbox(label, CSSUtil.hskip(hskip), ui.dom)
    end
    slap_design!(ui)
    Widget{:radiobuttons}(["options"=>options, "index" => ui["index"]], scope = ui, output = value, layout = dom"div.field"∘Widgets.scope)
end

function entry(T::WidgetTheme, s; className="", typ="radio", wdgtyp=typ, stack=(typ!="radio"), kwargs...)
    className = mergeclasses(getclass(:input, wdgtyp), className)
    f = stack ? node(:div, className="field") : tuple
    f(
        node(:input, className = className, attributes = Dict("name" => s, "type" => typ, "data-bind" => "checked : \$root.index, checkedValue: val, attr : {id : id}"))(),
        node(:label, attributes = Dict("data-bind" => "text : key, attr : {for : id}"))
    )
end

"""
```
radiobuttons(options::AbstractDict;
             value::Union{T, Observable} = first(values(options)))
```

e.g. `radiobuttons(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`radiobuttons(values::AbstractArray; kwargs...)`

`radiobuttons` with labels `string.(values)`
see `radiobuttons(options::AbstractDict; ...)` for more details

```
radiobuttons(options::AbstractObservable; kwargs...)
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
checkboxes(options::AbstractDict;
         value = first(values(options)))
```

A list of checkboxes whose item labels are the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `checkboxes(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`checkboxes(values::AbstractArray; kwargs...)`

`checkboxes` with labels `string.(values)`
see `checkboxes(options::AbstractDict; ...)` for more details

```
checkboxes(options::AbstractObservable; kwargs...)
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
toggles(options::AbstractDict;
         value = first(values(options)))
```

A list of toggle switches whose item labels are the keys of options.
Tthe observable will hold an array containing the values
of all selected items,
e.g. `toggles(OrderedDict("good"=>1, "better"=>2, "amazing"=>9001))`

`toggles(values::AbstractArray; kwargs...)`

`toggles` with labels `string.(values)`
see `toggles(options::AbstractDict; ...)` for more details

```
toggles(options::AbstractObservable; kwargs...)
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

        function $wdg(T::WidgetTheme, options::AbstractObservable; tag = $(Expr(:quote, tag)),
            className = getclass($(Expr(:quote, singlewdg)), "fullwidth"),
            activeclass = getclass($(Expr(:quote, singlewdg)), "active"),
            index = nothing, value = Some(nothing),
            label = nothing, readout = false, vskip = 1em, kwargs...)

            vals2idxs = map(Vals2Idxs, options)
            p = initvalueindex(value, index, vals2idxs; default = first(vals2idxs[]))
            value, index = p.first, p.second

            className = mergeclasses(getclass($(Expr(:quote, singlewdg))), className)

            btn = node(tag,
                node(:label, attributes = Dict("data-bind" => "text : key")),
                attributes=Dict("data-bind"=>
                "click: function () {\$root.index(val)}, css: {'$activeclass' : \$root.index() == val, '$className' : true}"),
            )
            option_array = _js_array(options; process = $process)
            template = node($(Expr(:quote, div)), className = getclass($(Expr(:quote, wdg))), attributes = "data-bind" => "foreach : options_js")(
                btn
            )

            label != nothing && (template = flex_row(wdglabel(label), template))
            ui = knockout(template, ["index" => index, "options_js" => option_array])
            slap_design!(ui)

            w = Widget{$(Expr(:quote, wdg))}(["options"=>options, "index" => ui["index"], "vals2idxs" => vals2idxs];
                scope = ui, output = value, layout = dom"div.field"∘Widgets.scope)
            if readout
                w.display = mask(map(parent, vals2idxs); index = index)
                w.layout = t -> vbox(dom"div.field"(Widgets.scope(t)), CSSUtil.vskip(vskip), t.display)
            end
            w
        end
    end
end

"""
`togglebuttons(options::AbstractDict; value::Union{T, Observable})`

Creates a set of toggle buttons whose labels are the keys of options.

`togglebuttons(values::AbstractArray; kwargs...)`

`togglebuttons` with labels `string.(values)`
see `togglebuttons(options::AbstractDict; ...)` for more details

```
togglebuttons(options::AbstractObservable; kwargs...)
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
`tabs(options::AbstractDict; value::Union{T, Observable})`

Creates a set of tabs whose labels are the keys of options. The label can be a link.

`tabs(values::AbstractArray; kwargs...)`

`tabs` with labels `values`
see `tabs(options::AbstractDict; ...)` for more details

```
tabs(options::AbstractObservable; kwargs...)
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
