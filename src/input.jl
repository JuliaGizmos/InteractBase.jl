function choosefile(::CSSFramework; class="interact-widget", kwargs...)
    s = """function (event){
        var filePath = this.\$refs.data;
        var fn = filePath.files[0];
        return this.filename = fn.path
    }
    """
    jfunc = WebIO.JSString(s)

    o = Observable("")
    ui = vue(dom"input[ref=data, type=file, v-on:change=onFileChange, class=$class]"(attributes = Dict(kwargs)),
        ["filename" => o], methods = Dict(:onFileChange => jfunc))
    primary_obs!(ui, "filename")
    slap_design!(ui)
end

function autocomplete(::CSSFramework, options, o=""; class="interact-widget")
    (o isa Observable) || (o = Observable(o))
    args = [dom"option[value=$opt]"() for opt in options]
    s = gensym()
    template = dom"div"(
        dom"input[list=$s, v-model=text, ref=listref, class=$class]"(),
        dom"datalist[id=$s]"(args...)
    )
    ui = vue(template, ["text"=>o]);
    primary_obs!(ui, "text")
    slap_design!(ui)
end

function input(::CSSFramework, o; postprocess=identity, typ="text", class="interact-widget", kwargs...)
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

function input(::CSSFramework; typ="text", kwargs...)
    if typ in ["checkbox", "radio"]
        o = false
    elseif typ in ["number", "range"]
        o = 0.0
    else
        o = ""
    end
    input(o; typ=typ, kwargs...)
end

function button(::CSSFramework, label = "Press me!"; clicks = Observable(0), class = "interact-widget")
    attrdict = Dict("v-on:click"=>"clicks += 1","class"=>class)
    template = dom"button"(label, attributes=attrdict)
    button = vue(template, ["clicks" => clicks]; obskey=:clicks)
    primary_obs!(button, "clicks")
    slap_design!(button)
end

function checkbox(::CSSFramework, o=false; label="", class="interact-widget", kwargs...)
    s = gensym() |> string
    postprocess = t -> dom"div.field"(t, dom"label[for=$s]"(label))
    input(NativeHTML(), o; typ="checkbox", id=s, class=class, postprocess=postprocess, kwargs...)
end

toggle(::CSSFramework, args...; kwargs...) = checkbox(NativeHTML(), args...; kwargs...)

function textbox(::CSSFramework, label=""; value="", class="interact-widget", kwargs...)
    s = gensym() |> string
    postprocess = t -> dom"div.field"(t, dom"label[for=$s]"(label))
    input(NativeHTML(), value; typ="text", id=s, class=class, postprocess=postprocess, kwargs...)
end

function slider(::CSSFramework, vals; value=medianelement(vals), kwargs...)
    input(value; typ="range", min=minimum(vals), max=maximum(vals), step=step(vals), kwargs...)
end
