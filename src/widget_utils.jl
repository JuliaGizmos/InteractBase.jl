using Vue

import WebIO: camel2kebab

# Get median elements of ranges, used for initialising sliders.
# Differs from median(r) in that it always returns an element of the range
medianidx(r) = (1+length(r)) ÷ 2
medianelement(r::Union{Range, Array}) = r[medianidx(r)]
medianval(r::Associative) = medianelement(collect(values(r)))
medianelement(r::Associative) = medianval(r)

inverse_dict(d::Associative) = Dict(zip(values(d), keys(d)))

const Propkey = Union{Symbol, String}

"""
`props2str(vbindprops::Dict{Propkey, String}, stringprops::Dict{String, String}`
input is
`vbindprops`: Dict of v-bind propnames=>values, e.g. Dict("max"=>"max", "min"=>"min"),
`stringprops`: Dict of vanilla string props, e.g. Dict("v-model"=>"value")
output is `"v-bind:max=max, v-bind:min=min, v-model=value"`
"""
function props2str(vbindprops::Dict{Propkey, String}, stringprops::Dict{String, String})
    vbindpropstr = ["v-bind:$key = $val" for (key, val) in vbindprops]
    vpropstr = ["$key = $val" for (key, val) in stringprops]
    join(vcat(vbindpropstr, vpropstr), ", ")
end

"""
`kwargs2vueprops(kwargs)` => `vbindprops, data`

Takes a vector of kwarg (propname, value) Tuples, returns neat properties
and data that can be passed to a vue instance.

Does camel2kebab conversion that allows passing normally kebab-cased html props
as camelCased keyword arguments.

To enable non-string values in html properties, we can use vue's "v-bind:".
To do so, a `(propname, value)` pair, passed as a kwarg, will be encoded as
`"v-bind:propkey=propname"`, (where `propkey = \$(camel2kebab(propname))`, i.e.
just the propname converted to kebab case). The value will be stored in a
corresponding entry in the returned `data` Dict, `propname=>value`

So we have the following for a ((camelCased) propname, value) pair:
`propkey == camel2kebab(propname)`
`propname == vbindprops[propkey]`
`data[propname] == value`
Note that the data dict requires the camelCased propname in the keys
"""
function kwargs2vueprops(kwargs; extra_vbinds=Dict())
    extradata = Dict(values(extra_vbinds))
    extravbind_dic = Dict{String, String}(
        zip(map(camel2kebab, keys(extra_vbinds)), keys(extradata)))
    data = Dict{Propkey, Any}(merge(Dict(kwargs), extradata))
    camelkeys = map(string, keys(data))
    propapropkeys = camel2kebab.(camelkeys) # kebabs are propa bo
    vbindprops = Dict{Propkey, String}(zip(propapropkeys, camelkeys))
    merge(vbindprops, extravbind_dic), data
end

function slap_design!(w::Scope, args)
    for arg in args
        import!(w, arg)
    end
    w
end

slap_design!(w::Scope, args::AbstractString...) = slap_design!(w::Scope, args)

slap_design!(w::Scope, args::WidgetTheme = gettheme()) =
    slap_design!(w::Scope, libraries(args))

slap_design!(n::Node, args...) = slap_design!(Scope()(n), args...)

slap_design!(w::Widget, args...) = (slap_design!(scope(w), args...); w)

isijulia() = isdefined(Main, :IJulia) && Main.IJulia.inited

_get(o::Observable) = o[]
_get(o) = o

_replace_className(class::Void, default) = default
_replace_className(class, default) = (Base.depwarn("class keyword is deprecated, use className instead", "class"); class)

_replace_style(s) = s
function _replace_style(s::AbstractString)
    Base.depwarn("""
        using strings for style is deprecated, use Dict of attribute=>value instead,
        e.g. `style=Dict("text-align" => "center", "width" => "100px")`
        """,
        "style"
    )
    entries = split(s, ';')
    d = Dict{String, String}()
    for el in entries
        v = split(el, ':')
        size(v) == (2,) && (d[strip(v[1])] = strip(v[2]))
    end
    d
end
