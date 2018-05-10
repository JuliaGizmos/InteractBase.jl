function choosefile(::NativeHTML; class="interact-widget", kwargs...)
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

function autocomplete(::NativeHTML, options, o=""; class="interact-widget")
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

function input(::NativeHTML, o; typ="text", class="interact-widget", kwargs...)
    (o isa Observable) || (o = Observable(o))
    vmodel = isa(o[], Number) ? "v-model.number" : "v-model"
    attrDict = merge(
        Dict(:type=>typ, Symbol(vmodel) => "value"),
        Dict(kwargs)
    )
    template = Node(:input, className=class, attributes = attrDict)()
    ui = vue(template, ["value"=>o])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

function input(::NativeHTML; typ="text", kwargs...)
    if typ in ["checkbox", "radio"]
        o = false
    elseif typ in ["number", "range"]
        o = 0.0
    else
        o = ""
    end
    input(o; typ=typ, kwargs...)
end

function button(::NativeHTML, label = "Press me!"; clicks = Observable(0), class = "interact-widget")
    attrdict = Dict("v-on:click"=>"clicks += 1","class"=>class)
    template = dom"button"(label, attributes=attrdict)
    button = vue(template, ["clicks" => clicks]; obskey=:clicks)
    primary_obs!(button, "clicks")
    slap_design!(button)
end

function checkbox(::NativeHTML, o=true; label="", class="interact-widget", kwargs...)
    s = gensym()
    (o isa Observable) || (o = Observable(o))
    attrDict = merge(
        Dict(:type=>"checkbox", :id => string(s), Symbol("v-model") => "value"),
        Dict(kwargs)
    )
    template1 = Node(:input, className=class, attributes = attrDict)()
    template = dom"div.field"(
        template1,
        dom"label[for=$s]"(label)
    )
    ui = vue(template, ["value"=>o])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

function textbox(::NativeHTML, label=""; value="", class="interact-widget", kwargs...)
    s = gensym()
    o = value
    (o isa Observable) || (o = Observable(o))
    attrDict = merge(
        Dict(:type=>"text", :id => string(s), Symbol("v-model") => "value"),
        Dict(kwargs)
    )
    template1 = Node(:input, className=class, attributes = attrDict)()
    template = dom"div.field"(
        template1,
        dom"label[for=$s]"(label)
    )
    ui = vue(template, ["value"=>o])
    primary_obs!(ui, "value")
    slap_design!(ui)
end

function slider(::NativeHTML, vals; value=medianelement(vals), kwargs...)
    input(value; typ="range", min=minimum(vals), max=maximum(vals), step=step(vals), kwargs...)
end
