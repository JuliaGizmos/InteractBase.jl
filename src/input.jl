"""
`filepicker(label="Choose a file..."; multiple=false, accept="*")`

Create a widget to select files.
If `multiple=true` the observable will hold an array containing the paths of all
selected files. Use `accept` to only accept some formats, e.g. `accept=".csv"`
"""
function filepicker(::WidgetTheme, lbl="Choose a file...";
    label=lbl, class="interact-widget", multiple=false, kwargs...)

    if multiple
        onFileUpload = """function (event){
            var fileArray = Array.from(this.\$refs.data.files)
            this.filename = fileArray.map(function (el) {return el.name;});
            return this.path = fileArray.map(function (el) {return el.path;});
        }
        """
        path = Observable(String[])
        filename = Observable(String[])
    else
        onFileUpload = """function (event){
            this.filename = this.\$refs.data.files[0].name;
            return this.path = this.\$refs.data.files[0].path;
        }
        """
        path = Observable("")
        filename = Observable("")
    end
    jfunc = WebIO.JSString(onFileUpload)
    attributes = Dict{Symbol, Any}(kwargs)
    multiple && (attributes[:multiple] = true)
    ui = vue(dom"input[ref=data, type=file, v-on:change=onFileChange, class=$class]"(attributes = attributes),
        ["path" => path, "filename" => filename], methods = Dict(:onFileChange => jfunc))
    primary_obs!(ui, "path")
    slap_design!(ui)
end

_parse(::Type{S}, x) where{S} = parse(S, x)
function _parse(::Type{Dates.Time}, x)
    h, m = parse.(Int, split(x, ':'))
    Dates.Time(h, m)
end

"""
`datepicker(value::Union{Dates.Date, Observable, Void}=nothing)`

Create a widget to select dates.
"""
function datepicker end

"""
`timepicker(value::Union{Dates.Time, Observable, Void}=nothing)`

Create a widget to select times.
"""
function timepicker end

for (func, typ, str) in [(:timepicker, :(Dates.Time), "time"), (:datepicker, :(Dates.Date), "date") ]
    @eval begin
        function $func(::WidgetTheme, val=nothing; value=val, kwargs...)
            if value == nothing
                internalvalue = Observable("")
                value = Observable{Union{$typ, Void}}(nothing)
            else
                (value isa Observable) || (value = Observable{Union{$typ, Void}}(value))
                internalvalue = Observable(string(value[]))
            end
            map!(t -> _parse($typ, t), value, internalvalue)
            ui = input(internalvalue; typ=$str, kwargs...)
            primary_obs!(ui, value)
            ui
        end
    end
end

"""
`colorpicker(value::Union{Color, Observable}=colorant"#000000")`

Create a widget to select colors.
"""
function colorpicker(::WidgetTheme, val=colorant"#000000"; value=val, kwargs...)
    (value isa Observable) || (value = Observable{Color}(value))
    internalvalue = Observable("#" * hex(value[]))
    map!(t -> parse(Colorant,t), value, internalvalue)
    ui = input(internalvalue; typ="color", kwargs...)
    primary_obs!(ui, value)
    ui
end

"""
`spinbox(label=""; value=nothing)`

Create a widget to select numbers with placeholder `label`
"""
function spinbox(::WidgetTheme, label=""; value=nothing, placeholder=label, kwargs...)
    if value == nothing
        internalvalue = Observable("")
        value = Observable{Union{Float64, Void}}(nothing)
    else
        (value isa Observable) || (value = Observable{Union{Float64, Void}}(value))
        internalvalue = Observable(string(value[]))
    end
    on(t -> t in ["", "-"] || (value[] = parse(Float64, t)), internalvalue)
    ui = input(internalvalue; placeholder=placeholder, typ="number", kwargs...)
    primary_obs!(ui, value)
    ui
end

"""
`autocomplete(options, label=""; value="")`

Create a textbox input with autocomplete options specified by `options`, with `value`
as initial value and `label` as label.
"""
function autocomplete(::WidgetTheme, options, args...; outer=dom"div", kwargs...)
    opts = [dom"option[value=$opt]"() for opt in options]
    s = gensym()
    t = textbox(args...; list=s, kwargs...)
    scope(t).dom = outer(scope(t).dom, dom"datalist[id=$s]"(opts...))
    t
end

"""
`input(o; typ="text")`

Create an HTML5 input element of type `type` (e.g. "text", "color", "number", "date") with `o`
as initial value.
"""
function input(::WidgetTheme, o; typ="text", class="interact-widget",
    internalvalue=nothing, displayfunction=js"function (){return this.value;}", attributes=Dict(), kwargs...)

    (o isa Observable) || (o = Observable(o))
    (internalvalue == nothing) && (internalvalue = o)
    vmodel = isa(o[], Number) ? "v-model.number" : "v-model"
    attrDict = merge(
        attributes,
        Dict(:type=>typ, Symbol(vmodel) => "internalvalue"),
        Dict(kwargs)
    )
    template = Node(:input, className=class, attributes = attrDict)()
    ui = vue(template, ["value"=>o, "internalvalue"=>internalvalue], computed = Dict("displayedvalue"=>displayfunction))
    primary_obs!(ui, "value")
    slap_design!(ui)
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

button(::WidgetTheme; label="Press me!", kwargs...) = button(gettheme(), label; kwargs...)

"""
`button(content... = "Press me!"; value=0)`

A button. `content` goes inside the button.
Note the button `content` supports a special `clicks` variable, that gets incremented by `1`
with each click e.g.: `button("clicked {{clicks}} times")`.
The `clicks` variable is initialized at `value=0`
"""
function button(::WidgetTheme, content... = "Press me!"; value = 0, class = "interact-widget")
    (value isa Observable) || (value = Observable(value))
    attrdict = Dict("v-on:click"=>"clicks += 1","class"=>class)
    template = dom"button"(content..., attributes=attrdict)
    button = vue(template, ["clicks" => value]; obskey=:clicks)
    primary_obs!(button, "clicks")
    slap_design!(button)
end

"""
`checkbox(value::Union{Bool, Observable}=false; label)`

A checkbox.
e.g. `checkbox(label="be my friend?")`
"""
function checkbox(::WidgetTheme, o=false; value=o, label="", class="interact-widget", outer=dom"div.field", labelclass="interact-widget", kwargs...)
    s = gensym() |> string
    (label isa Tuple) || (label = (label,))
    ui = input(value; typ="checkbox", id=s, class=class, kwargs...)
    scope(ui).dom = outer(scope(ui).dom, dom"label.$labelclass[for=$s]"(label...))
    ui
end

"""
`toggle(value::Union{Bool, Observable}=false; label)`

A toggle switch.
e.g. `toggle(label="be my friend?")`
"""
toggle(::WidgetTheme, args...; kwargs...) = checkbox(args...; kwargs...)

"""
`textbox(label=""; value="")`

Create a text input area with an optional `label`
e.g. `textbox("enter number:")`. Use `typ=...` to specify the type of text. For example
`typ="email"` or `typ=password`
"""
function textbox(::WidgetTheme, label=""; placeholder=label, value="", typ="text", kwargs...)
    input(value; typ=typ, placeholder=placeholder, kwargs...)
end

"""
```
function slider(vals::Range; # Range
                value=medianelement(valse),
                label="", kwargs...)
```

Creates a slider widget which can take on the values in `vals`, and updates
observable `value` when the slider is changed:
"""
function slider(::WidgetTheme, vals::Range; isinteger=(eltype(vals) <: Integer), showvalue=true,
    label=nothing, value=medianelement(vals), precision=6, kwargs...)

    (value isa Observable) || (value = convert(eltype(vals), value))
    displayfunction = isinteger ? js"function () {return this.value;}" :
                                  js"function () {return this.value.toPrecision($precision);}"
    ui = input(value; displayfunction=displayfunction,
        typ="range", min=minimum(vals), max=maximum(vals), step=step(vals) , kwargs...)
    if (label != nothing) || showvalue
        scope(ui).dom = showvalue ?  flex_row(wdglabel(label), scope(ui).dom, dom"div"("{{displayedvalue}}")):
                                     flex_row(wdglabel(label), scope(ui).dom)
    end
    ui
end

function slider(::WidgetTheme, vals::AbstractVector; value=medianelement(vals), kwargs...)
    (value isa Observable) || (value = Observable{eltype(vals)}(value))
    idxs::Range = indices(vals)[1]
    idx = Observable(findfirst(t -> t == value[], vals))
    on(t -> value[] = vals[t], idx)
    slider(idxs; value=value, internalvalue=idx, isinteger=(eltype(vals) <: Integer))
end

function wdglabel(T::WidgetTheme, text; padt=5, padr=10, padb=0, padl=10, class="interact-widget", style = Dict())
    fullstyle = Dict(:padding=>"$(padt)px $(padr)px $(padb)px $(padl)px")
    Node(:label, text, className=class, style = merge(fullstyle, style))
end

function flex_row(a,b,c=dom"div"())
    dom"div.[style=display:flex; justify-content:center; align-items:center;]"(
        dom"div[style=text-align:right;width:18%]"(a),
        dom"div[style=width:60%; margin: 0 2%]"(b),
        dom"div[style=width:18%]"(c)
    )
end

flex_row(a) =
    dom"div.[style=display:flex; justify-content:center; align-items:center;]"(a)
