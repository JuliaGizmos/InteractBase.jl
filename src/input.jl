"""
`filepicker(label=""; placeholder="", multiple=false, accept="*")`
Create a widget to select files.
If `multiple=true` the observable will hold an array containing the paths of all
selected files. Use `accept` to only accept some formats, e.g. `accept=".csv"`
"""
function filepicker(::WidgetTheme; postprocess=identity, class="interact-widget", kwargs...)
    s = """function (event){
        return this.filename = \$event.target.files[0].path
    }
    """
    jfunc = WebIO.JSString(s)

    o = Observable("")
    ui = vue(postprocess(dom"input[ref=data, type=file, v-on:change=onFileChange, class=$class]"(attributes = Dict(kwargs))),
        ["filename" => o], methods = Dict(:onFileChange => jfunc))
    primary_obs!(ui, "filename")
    slap_design!(ui)
end

function autocomplete(::WidgetTheme, options, o=""; class="interact-widget", outer = dom"div")
    (o isa Observable) || (o = Observable(o))
    args = [dom"option[value=$opt]"() for opt in options]
    s = gensym()
    template = outer(
        dom"input[list=$s, v-model=text, ref=listref, class=$class]"(),
        dom"datalist[id=$s]"(args...)
    )
    ui = vue(template, ["text"=>o]);
    primary_obs!(ui, "text")
    slap_design!(ui)
end

function input(::WidgetTheme, o; postprocess=identity, typ="text", class="interact-widget", kwargs...)
    (o isa Observable) || (o = Observable(o))
    vmodel = isa(o[], Number) ? "v-model.number" : "v-model"
    attrDict = merge(
        Dict(:type=>typ, Symbol(vmodel) => "value"),
        Dict(kwargs)
    )
    template = Node(:input, className=class, attributes = attrDict)() |> postprocess
    ui = vue(template, ["value"=>o])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

function input(T::WidgetTheme; typ="text", kwargs...)
    if typ in ["checkbox", "radio"]
        o = false
    elseif typ in ["number", "range"]
        o = 0.0
    else
        o = ""
    end
    input(T, o; typ=typ, kwargs...)
end

function button(::WidgetTheme, label = "Press me!"; clicks = Observable(0), class = "interact-widget")
    attrdict = Dict("v-on:click"=>"clicks += 1","class"=>class)
    template = dom"button"(label, attributes=attrdict)
    button = vue(template, ["clicks" => clicks]; obskey=:clicks)
    primary_obs!(button, "clicks")
    slap_design!(button)
end

function checkbox(T::WidgetTheme, o=false; label="", class="interact-widget", outer = dom"div.field", kwargs...)
    s = gensym() |> string
    postprocess = t ->outer(t, dom"label[for=$s]"(label))
    input(T, o; typ="checkbox", id=s, class=class, postprocess=postprocess, kwargs...)
end

toggle(T::WidgetTheme, args...; kwargs...) = checkbox(T, args...; kwargs...)

function textbox(T::WidgetTheme, label=nothing; value="", class="interact-widget", kwargs...)
    input(T, value; typ="text", class=class, kwargs...)
end

function slider(T::WidgetTheme, vals; value=medianelement(vals), kwargs...)
    input(T, value; typ="range", min=minimum(vals), max=maximum(vals), step=step(vals), kwargs...)
end
