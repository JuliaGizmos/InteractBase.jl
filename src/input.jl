function choosefile(; class="interact-widget")
    s = """function (event){
        var filePath = this.\$refs.data;
        var fn = filePath.files[0];
        return this.filename = fn.path
    }
    """
    jfunc = WebIO.JSString(s)

    o = Observable("")
    ui = vue(dom"input[ref=data, type=file, v-on:change=onFileChange, class=$class]"(),
        ["filename" => o], methods = Dict(:onFileChange => jfunc))
    primary_obs!(ui, "filename")
    slap_design!(ui)
end

function autocomplete(options, o=""; class="interact-widget")
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

function input(o; typ="text", class="interact-widget", kwargs...)
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

function input(; typ="text", kwargs...)
    if typ in ["checkbox", "radio"]
        o = false
    elseif typ in ["number", "range"]
        o = 0.0
    else
        o = ""
    end
    input(o; typ=typ, kwargs...)
end

function button(label = "Press me!"; clicks = Observable(0), class = "interact-widget")
    attrdict = Dict("v-on:click"=>"clicks += 1","class"=>class)
    template = dom"button"(label, attributes=attrdict)
    button = vue(template, ["clicks" => clicks]; obskey=:clicks)
    primary_obs!(button, "clicks")
    slap_design!(button)
end
