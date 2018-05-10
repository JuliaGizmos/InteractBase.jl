function dropdown(::CSSFramework, options, o = nothing; postprocess = identity, kwargs...)
    extra_attr = Dict(kwargs)
    (o == nothing) && (o = get(extra_attr, :multiple, false) ? String[] : "")
    (o isa Observable) || (o = Observable(o))
    args = [dom"option"(opt) for opt in options]
    s = gensym()
    attrDict = merge(
        Dict(Symbol("v-model") => "value"),
        extra_attr
    )
    template = Node(:select, args..., attributes = attrDict) |> postprocess
    ui = vue(template, ["value"=>o]);
    primary_obs!(ui, "value")
    slap_design!(ui)
end
