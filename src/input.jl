"""
`filepicker(label=""; placeholder="", multiple=false, accept="*")`

Create a widget to select files.
If `multiple=true` the observable will hold an array containing the paths of all
selected files. Use `accept` to only accept some formats, e.g. `accept=".csv"`
"""
function filepicker(::WidgetTheme; postprocess=identity, class="interact-widget", multiple=false, kwargs...)
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
    ui = vue(postprocess(dom"input[ref=data, type=file, v-on:change=onFileChange, class=$class]"(attributes = attributes)),
        ["path" => path, "filename" => filename], methods = Dict(:onFileChange => jfunc))
    primary_obs!(ui, "path")
    slap_design!(ui)
end

"""
`autocomplete(options, label=nothing; value="")`

Create a textbox input with autocomplete options specified by `options`, with `value`
as initial value and `label` as label.
"""
function autocomplete(::WidgetTheme, options, label=nothing; outer=dom"div", kwargs...)
    args = [dom"option[value=$opt]"() for opt in options]
    s = gensym()
    postprocess = t -> outer(
        t,
        dom"datalist[id=$s]"(args...)
    )
    textbox(label; list=s, postprocess=postprocess, kwargs...)
end

"""
`input(o; typ="text")`

Create an HTML5 input element of type `type` (e.g. "text", "color", "number", "date") with `o`
as initial value.
"""
function input(::WidgetTheme, o; postprocess=identity, typ="text", class="interact-widget",
    internalvalue=nothing, displayfunction=js"function (){return this.value;}", kwargs...)

    (o isa Observable) || (o = Observable(o))
    (internalvalue == nothing) && (internalvalue = o)
    vmodel = isa(o[], Number) ? "v-model.number" : "v-model"
    attrDict = merge(
        Dict(:type=>typ, Symbol(vmodel) => "internalvalue"),
        Dict(kwargs)
    )
    template = Node(:input, className=class, attributes = attrDict)() |> postprocess
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

"""
`button(content=""; clicks::Observable)`

A button. `content` goes inside the button.
Note the button `content` supports a special `clicks` variable, e.g.:
`button("clicked {{clicks}} times")`
"""
function button(::WidgetTheme, label = "Press me!"; clicks = 0, class = "interact-widget")
    (clicks isa Observable) || (clicks = Observable(clicks))
    attrdict = Dict("v-on:click"=>"clicks += 1","class"=>class)
    template = dom"button"(label, attributes=attrdict)
    button = vue(template, ["clicks" => clicks]; obskey=:clicks)
    primary_obs!(button, "clicks")
    slap_design!(button)
end

"""
`checkbox(checked::Union{Bool, Observable}=false; label)`

A checkbox.
e.g. `checkbox(label="be my friend?")`
"""
function checkbox(::WidgetTheme, o=false; label="", class="interact-widget", outer=dom"div.field", labelclass="interact-widget", kwargs...)
    s = gensym() |> string
    (label isa Tuple) || (label = (label,))
    postprocess = t -> outer(t, dom"label.$labelclass[for=$s]"(label...))
    input(o; typ="checkbox", id=s, class=class, postprocess=postprocess, kwargs...)
end

"""
`toggle(checked::Union{Bool, Observable}=false; label)`

A toggle switch.
e.g. `toggle(label="be my friend?")`
"""
toggle(::WidgetTheme, args...; kwargs...) = checkbox(args...; kwargs...)

"""
`textbox(label=""; text::Union{String, Observable})`

Create a text input area with an optional `label`
e.g. `textbox("enter number:")`
"""
function textbox(::WidgetTheme, label=""; value="", class="interact-widget", kwargs...)
    input(value; typ="text", placeholder=label, class=class, kwargs...)
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
    label=nothing, value=medianelement(vals), postprocess=identity, precision=6, kwargs...)

    (value isa Observable) || (value = convert(eltype(vals), value))
    postproc = function (t)
        (label == nothing) && !showvalue && return t
        showvalue ? flex_row(wdglabel(label), t, dom"div"("{{displayedvalue}}")) :
            flex_row(wdglabel(label), t)
    end

    displayfunction = isinteger ? js"function () {return this.value;}" :
                                  js"function () {return this.value.toPrecision($precision);}"
    input(value; displayfunction=displayfunction,
        postprocess = postproc∘postprocess, typ="range", min=minimum(vals), max=maximum(vals), step=step(vals) , kwargs...)
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
