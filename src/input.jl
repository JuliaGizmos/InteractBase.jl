_basename(v::AbstractArray) = basename.(v)
_basename(::Nothing) = nothing
_basename(v) = basename(v)

"""
`filepicker(label="Choose a file..."; multiple=false, accept="*")`

Create a widget to select files.
If `multiple=true` the observable will hold an array containing the paths of all
selected files. Use `accept` to only accept some formats, e.g. `accept=".csv"`
"""
function filepicker(::WidgetTheme, lbl="Choose a file..."; attributes=PropDict(),
    label=lbl, className="", multiple=false, value=multiple ? String[] : "",  kwargs...)

    (value isa AbstractObservable) || (value = Observable{Any}(value))
    filename = Observable{Any}(_basename(value[]))

    if multiple
        onFileUpload = js"""function (data, e){
            var files = e.target.files;
            var fileArray = Array.from(files);
            this.filename(fileArray.map(function (el) {return el.name;}));
            return this.path(fileArray.map(function (el) {return el.path;}));
        }
        """
    else
        onFileUpload = js"""function(data, e) {
            var files = e.target.files;
            this.filename(files[0].name);
            return this.path(files[0].path);
        }
        """
    end
    multiple && (attributes=merge(attributes, PropDict(:multiple => true)))
    attributes = merge(attributes, PropDict(:type => "file", :style => "display: none;",
        Symbol("data-bind") => "event: {change: onFileUpload}"))
    className = mergeclasses(getclass(:input, "file"), className)
    template = dom"div[style=display:flex; align-items:center;]"(
        node(:label, className=getclass(:input, "file", "label"))(
            node(:input; className=className, attributes=attributes, kwargs...),
            node(:span,
                node(:span, (node(:i, className = getclass(:input, "file", "icon"))), className=getclass(:input, "file", "span", "icon")),
                node(:span, label, className=getclass(:input, "file", "span", "label")),
                className=getclass(:input, "file", "span"))
        ),
        node(:span, attributes = Dict("data-bind" => " text: filename() == '' ? 'No file chosen' : filename()"),
            className = getclass(:input, "file", "name"))
    )

    observs = ["path" => value, "filename" => filename]
    ui = knockout(template, observs, methods = ["onFileUpload" => onFileUpload])
    slap_design!(ui)
    Widget{:filepicker}(observs, scope = ui, output = ui["path"], layout = dom"div.field"∘Widgets.scope)
end

_parse(::Type{S}, x) where{S} = parse(S, x)
function _parse(::Type{Dates.Time}, x)
    h, m = parse.(Int, split(x, ':'))
    Dates.Time(h, m)
end

"""
`datepicker(value::Union{Dates.Date, Observable, Nothing}=nothing)`

Create a widget to select dates.
"""
function datepicker end

"""
`timepicker(value::Union{Dates.Time, Observable, Nothing}=nothing)`

Create a widget to select times.
"""
function timepicker end

for (func, typ, str, unit) in [(:timepicker, :(Dates.Time), "time", Dates.Second), (:datepicker, :(Dates.Date), "date", Dates.Day) ]
    @eval begin
        function $func(::WidgetTheme, val=nothing; value=val, kwargs...)
            (value isa AbstractObservable) || (value = Observable{Union{$typ, Nothing}}(value))
            f = x -> x === nothing ? "" : split(string(x), '.')[1]
            g = t -> _parse($typ, t)
            pair = ObservablePair(value, f=f, g=g)
            ui = input(pair.second; typ=$str, kwargs...)
            Widget{$(Expr(:quote, func))}(ui, output = value)
        end

        function $func(T::WidgetTheme, vals::AbstractRange, val=medianelement(vals); value=val, kwargs...)
            f = x -> x === nothing ? "" : split(string(x), '.')[1]
            fs = x -> x === nothing ? "" : split(string(convert($unit, x)), ' ')[1]
            $func(T; value=value, min=f(minimum(vals)), max=f(maximum(vals)), step=fs(step(vals)), kwargs...)
        end
    end
end

"""
`colorpicker(value::Union{Color, Observable}=colorant"#000000")`

Create a widget to select colors.
"""
function colorpicker(::WidgetTheme, val=colorant"#000000"; value=val, kwargs...)
    (value isa AbstractObservable) || (value = Observable{Color}(value))
    f = t -> "#"*hex(t)
    g = t -> parse(Colorant,t)
    pair = ObservablePair(value, f=f, g=g)
    ui = input(pair.second; typ="color", kwargs...)
    Widget{:colorpicker}(ui, output = value)
end

"""
`spinbox([range,] label=""; value=nothing)`

Create a widget to select numbers with placeholder `label`. An optional `range` first argument
specifies maximum and minimum value accepted as well as the step.
"""
function spinbox(::WidgetTheme, label=""; value=nothing, placeholder=label, isinteger=nothing, kwargs...)
    isinteger = something(isinteger, isa(_val(value), Integer))
    T = isinteger ? Int : Float64
    (value isa AbstractObservable) || (value = Observable{Union{T, Nothing}}(value))
    ui = input(value; isnumeric=true, placeholder=placeholder, typ="number", kwargs...)
    Widget{:spinbox}(ui, output = value)
end

spinbox(T::WidgetTheme, vals::AbstractRange, args...; value=first(vals), isinteger=(eltype(vals) <: Integer), kwargs...) =
    spinbox(T, args...; value=value, isinteger=isinteger, min=minimum(vals), max=maximum(vals), step=step(vals), kwargs...)

"""
`autocomplete(options, label=""; value="")`

Create a textbox input with autocomplete options specified by `options`, with `value`
as initial value and `label` as label.
"""
function autocomplete(::WidgetTheme, options, args...; attributes=PropDict(), kwargs...)
    (options isa AbstractObservable) || (options = Observable{Any}(options))
    option_array = _js_array(options)
    s = gensym()
    attributes = merge(attributes, PropDict(:list => s))
    t = textbox(args...; extra_obs=["options_js" => option_array], attributes=attributes, kwargs...)
    Widgets.scope(t).dom = node(:div,
        Widgets.scope(t).dom,
        node(:datalist, node(:option, attributes=Dict("data-bind"=>"value : key"));
            attributes = Dict("data-bind" => "foreach : options_js", "id" => s))
    )
    w = Widget{:autocomplete}(t)
    w[:options] = options
    w
end

"""
`input(o; typ="text")`

Create an HTML5 input element of type `type` (e.g. "text", "color", "number", "date") with `o`
as initial value.
"""
function input(::WidgetTheme, o; extra_js=js"", extra_obs=[], label=nothing, typ="text", wdgtyp=typ,
    className="", style=Dict(), internalvalue=nothing, isnumeric=Knockout.isnumeric(o),
    displayfunction=js"function (){return this.value();}", attributes=Dict(), bind="value", valueUpdate="input", kwargs...)

    (o isa AbstractObservable) || (o = Observable(o))
    isnumeric && (bind == "value") && (bind = "numericValue")
    bindto = (internalvalue == nothing) ? "value" : "internalvalue"
    data = Pair{String, AbstractObservable}["changes" => Observable(0), "value" => o]
    (internalvalue !== nothing) && push!(data, "internalvalue" => internalvalue)
    append!(data, (string(key) => val for (key, val) in extra_obs))
    attrDict = merge(
        attributes,
        Dict(:type => typ, Symbol("data-bind") => "$bind: $bindto, valueUpdate: '$valueUpdate', event: {change : function () {this.changes(this.changes()+1)}}")
    )
    className = mergeclasses(getclass(:input, wdgtyp), className)
    template = node(:input; className=className, attributes=attrDict, style=style, kwargs...)()
    ui = knockout(template, data, extra_js, computed = ["displayedvalue" => displayfunction])
    (label != nothing) && (ui.dom = flex_row(wdglabel(label), ui.dom))
    slap_design!(ui)
    Widget{:input}(data, scope = ui, output = ui["value"], layout = dom"div.field"∘Widgets.scope)
end

function input(::WidgetTheme; typ="text", kwargs...)
    if typ in ["checkbox", "radio"]
        o = false
    elseif typ in ["number", "range"]
        o = 0.0
    else
        o = ""
    end
    input(o; typ=typ, kwargs...)
end

function input(T::WidgetTheme, ::Type{S}, args...; isinteger=nothing, kwargs...) where {S<:Number}
    (isinteger === nothing) && (isinteger = S<:Integer ? true : S<:AbstractFloat ? false : nothing)
    spinbox(T, args...; isinteger=isinteger, kwargs...)
end

input(T::WidgetTheme, ::Type{<:Bool}, args...; kwargs...) = toggle(T, args...; kwargs...)
input(T::WidgetTheme, ::Type{<:AbstractString}, args...; kwargs...) = textbox(T, args...; kwargs...)
input(T::WidgetTheme, ::Type{<:Dates.Date}, args...; kwargs...) = datepicker(T, args...; kwargs...)
input(T::WidgetTheme, ::Type{<:Dates.Time}, args...; kwargs...) = timepicker(T, args...; kwargs...)
input(T::WidgetTheme, ::Type{<:Color}, args...; kwargs...) = colorpicker(T, args...; kwargs...)

"""
`button(content... = "Press me!"; value=0)`

A button. `content` goes inside the button.
Note the button `content` supports a special `clicks` variable, that gets incremented by `1`
with each click e.g.: `button("clicked {{clicks}} times")`.
The `clicks` variable is initialized at `value=0`
"""
function button(::WidgetTheme, content...; label = "Press me!", value = 0, style = Dict{String, Any}(),
    className = getclass(:button, "primary"), attributes=Dict(), kwargs...)

    isempty(content) && (content = (label,))
    (value isa AbstractObservable) || (value = Observable(value))
    className = "delete" in split(className, ' ') ? className : mergeclasses(getclass(:button), className)
    attrdict = merge(
        Dict("data-bind"=>"click : function () {this.clicks(this.clicks()+1)}"),
        attributes
    )
    template = node(:button, content...; className=className, attributes=attrdict, style=style, kwargs...)
    button = knockout(template, ["clicks" => value])
    slap_design!(button)
    Widget{:button}(scope = button, output = value, layout = dom"div.field"∘Widgets.scope)
end

for wdg in [:toggle, :checkbox]
    @eval begin
        $wdg(::WidgetTheme, value, lbl::AbstractString=""; label=lbl, kwargs...) =
            $wdg(gettheme(); value=value, label=label, kwargs...)

        $wdg(::WidgetTheme, label::AbstractString, val=false; value=val, kwargs...) =
            $wdg(gettheme(); value=value, label=label, kwargs...)

        $wdg(::WidgetTheme, value::AbstractString, label::AbstractString; kwargs...) =
            error("value cannot be a string")

        function $wdg(::WidgetTheme; bind="checked", valueUpdate="change", value=false, label="", labelclass="", kwargs...)
            s = gensym() |> string
            (label isa Tuple) || (label = (label,))
            widgettype = $(Expr(:quote, wdg))
            wdgtyp = string(widgettype)
            labelclass = mergeclasses(getclass(:input, wdgtyp, "label"), labelclass)
            ui = input(value; bind=bind, typ="checkbox", valueUpdate="change", wdgtyp=wdgtyp, id=s, kwargs...)
            Widgets.scope(ui).dom = dom"div.field"(Widgets.scope(ui).dom, dom"label[className=$labelclass, for=$s]"(label...))
            Widget{widgettype}(ui)
        end
    end
end

"""
`checkbox(value::Union{Bool, AbstractObservable}=false; label)`

A checkbox.
e.g. `checkbox(label="be my friend?")`
"""
function checkbox end

"""
`toggle(value::Union{Bool, AbstractObservable}=false; label)`

A toggle switch.
e.g. `toggle(label="be my friend?")`
"""
function toggle end

"""
`textbox(hint=""; value="")`

Create a text input area with an optional placeholder `hint`
e.g. `textbox("enter number:")`. Use `typ=...` to specify the type of text. For example
`typ="email"` or `typ=password`. Use `multiline=true` to display a `textarea` spanning
several lines.
"""
function textbox(::WidgetTheme, hint=""; multiline=false, placeholder=hint, value="", typ="text", kwargs...)
    multiline && return textarea(gettheme(); placeholder=placeholder, value=value, kwargs...)
    Widget{:textbox}(input(value; typ=typ, placeholder=placeholder, kwargs...))
end

"""
`textarea(hint=""; value="")`

Create a textarea with an optional placeholder `hint`
e.g. `textarea("enter number:")`. Use `rows=...` to specify how many rows to display
"""
function textarea(::WidgetTheme, hint=""; label=nothing, className="",
    placeholder=hint, value="", attributes=Dict(), style=Dict(), bind="value", valueUpdate = "input", kwargs...)

    (value isa AbstractObservable) || (value = Observable(value))
    attrdict = convert(PropDict, attributes)
    attrdict[:placeholder] = placeholder
    attrdict["data-bind"] = "$bind: value, valueUpdate: '$valueUpdate'"
    className = mergeclasses(getclass(:textarea), className)
    template = node(:textarea; className=className, attributes=attrdict, style=style, kwargs...)
    ui = knockout(template, ["value" => value])
    (label != nothing) && (ui.dom = flex_row(wdglabel(label), ui.dom))
    slap_design!(ui)
    Widget{:textarea}(scope = ui, output = ui["value"], layout = dom"div.field"∘Widgets.scope)
end

"""
```
function nativeslider(vals::AbstractRange;
                value=medianelement(vals),
                label=nothing, readout=true, kwargs...)
```

Creates a slider widget which can take on the values in `vals`, and updates
observable `value` when the slider is changed.
"""
function nativeslider(::WidgetTheme, vals::AbstractRange;
    className=getclass(:input, "range", "fullwidth"),
    isinteger=(eltype(vals) <: Integer), readout=true, showvalue=nothing,
    label=nothing, value=medianelement(vals), precision=6, kwargs...)

    if showvalue !== nothing
        Base.depwarn("`showvalue` kewyword argument is deprecated use `readout` instead")
        readout = showvalue
    end
    (value isa AbstractObservable) || (value = convert(eltype(vals), value))
    displayfunction = isinteger ? js"function () {return this.value();}" :
                                  js"function () {return this.value().toPrecision($precision);}"
    ui = input(value; displayfunction=displayfunction,
        typ="range", min=minimum(vals), max=maximum(vals), step=step(vals), className=className, kwargs...)
    if (label != nothing) || readout
        Widgets.scope(ui).dom = readout ?
            flex_row(wdglabel(label), Widgets.scope(ui).dom, node(:p, attributes = Dict("data-bind" => "text: displayedvalue"))) :
            flex_row(wdglabel(label), Widgets.scope(ui).dom)
    end
    Widget{:nativeslider}(ui)
end

function nativeslider(::WidgetTheme, vals::AbstractVector; value=medianelement(vals), kwargs...)
    (value isa AbstractObservable) || (value = Observable{eltype(vals)}(value))
    (vals isa Array) || (vals = collect(vals))
    idxs::AbstractRange = 1:(length(vals))
    idx = Observable(findfirst(t -> t == value[], vals))
    extra_js = js"""
    this.values = JSON.parse($(JSON.json(vals)))
    this.internalvalue.subscribe(function (value){
        this.value(this.values[value-1]);
    }, this)
    this.value.subscribe(function (value){
        var index = this.values.indexOf(value);
        this.internalvalue(index+1);
    }, this)
    """
    nativeslider(idxs; extra_js=extra_js, value=value, internalvalue=idx, isinteger=(eltype(vals) <: Integer), kwargs...)
end

function wdglabel(T::WidgetTheme, text; padt=5, padr=10, padb=0, padl=10,
    className="", style = Dict(), kwargs...)

    className = mergeclasses(getclass(:wdglabel), className)
    padding = Dict(:padding=>"$(padt)px $(padr)px $(padb)px $(padl)px")
    node(:label, text; className=className, style = merge(padding, style), kwargs...)
end

function flex_row(a,b,c=dom"div"())
    dom"div.[style=display:flex; justify-content:center; align-items:center;]"(
        dom"div[style=text-align:right;width:18%]"(a),
        dom"div[style=flex-grow:1; margin: 0 2%]"(b),
        dom"div[style=width:18%]"(c)
    )
end

flex_row(a) =
    dom"div.[style=display:flex; justify-content:center; align-items:center;]"(a)
