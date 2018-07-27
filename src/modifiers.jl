function tooltip!(wdg::AbstractWidget, args...; kwargs...)
    tooltip!(primary_node(wdg)::Node, args...; kwargs...)
    return wdg
end

function tooltip!(n::Node, tooltip; className = "")
    d = props(n)
    get!(d, :attributes, Dict{String, Any})
    get!(d, :className, "")
    d[:attributes]["data-tooltip"] = tooltip
    d[:className] = mergeclasses(d[:className], className, "tooltip")
    n
end

function primary_node(w::Widget)
    w.scope !== nothing && return w.scope.dom
    nodes = Iterators.filter(t -> isa(t, Node), values(w.children))
    isempty(nodes) || return first(nodes)
    error("primary node not defined for widget $w")
end