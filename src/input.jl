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

function autocomplete(options; label = "", placeholder = "")
    onSelect = """function (event){
        return this.text = this.\$refs.listref.value;
    }
    """
    onSelect = WebIO.JSString(onSelect)
    args = [dom"option[value=$opt]"() for opt in options]
    s = gensym()
    template = dom"div"(
        dom"label"(label),
        dom"br"(),
        dom"input[list=$s, v-on:input=onSelect, ref=listref, value=$placeholder]"(),
        dom"datalist[id=$s]"(args...)
    )
    o = Observable(placeholder)
    ui = vue(template, ["text"=>o], methods = Dict("onSelect"=>onSelect));
    primary_obs!(ui, "text")
    ui
end


function numericalinput(value=0; min=0, max=100, step=1, typ="number", class="interact-widget")
    T = eltype(min:step:max) <: AbstractFloat ? Float64 : Int
    parser = (T == Int) ? "parseInt" : "parseFloat"
    onChange = js"""function (event){
         return this.value = $parser(event)
     }
     """
    if !(value isa Observable)
        value = Observable{T}(value)
    end
    template = dom"""input[v-on:change=onChange, value=$(value[]), type=$typ, min=$min, max=$max, step=$step]"""()
    ui = vue(template, ["value"=>value], methods = Dict("onChange" => onChange))
    primary_obs!(ui, "value")
    ui
end

function input(o=""; typ="text", class="interact-widget")
    (o isa Observable) || (o == Observable(o))
    template = dom"input[type=$typ, v-model=value, class=$class]"()
    ui = vue(template, ["value"=>o])
    primary_obs!(ui, "value")
    ui
end
