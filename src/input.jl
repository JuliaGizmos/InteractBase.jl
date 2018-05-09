function choosefile()
    s = """function (event){
        var filePath = this.\$refs.data;
        var fn = filePath.files[0];
        return this.filename = fn.path
    }
    """
    jfunc = WebIO.JSString(s)

    o = Observable("")
    ui = vue(dom"input[ref=data, type=file, v-on:change=onFileChange]"(),
        ["filename" => o], methods = Dict(:onFileChange => jfunc))
    primary_obs!(ui, "filename")
    ui
end

function autocomplete(options, o="")
    (o isa Observable) || (o = Observable(o))
    onSelect = """function (event){
        return this.text = this.\$refs.listref.value;
    }
    """
    onSelect = WebIO.JSString(onSelect)
    args = [dom"option[value=$opt]"() for opt in options]
    s = gensym()
    template = dom"div"(
        dom"input[list=$s, v-on:input=onSelect, ref=listref, value=$(o[])]"(),
        dom"datalist[id=$s]"(args...)
    )
    ui = vue(template, ["text"=>o], methods = Dict("onSelect"=>onSelect));
    primary_obs!(ui, "text")
    ui
end

function input(o=""; typ="text", class="interact-widget", kwargs...)
    (o isa Observable) || (o = Observable(o))
    vmodel = isa(o[], Number) ? "v-model.number" : "v-model"
    attrDict = merge(
        Dict(:type=>typ, Symbol(vmodel) => "value"),
        Dict(kwargs)
    )
    template = Node(:input, className=class, attributes = attrDict)()
    ui = vue(template, ["value"=>o])
    primary_obs!(ui, "value")
    ui
end
