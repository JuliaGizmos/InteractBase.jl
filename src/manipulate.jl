export @manipulate, widget

function make_widget(binding)
    if binding.head != :(=)
        error("@manipulate syntax error.")
    end
    sym, expr = binding.args
    Expr(:call, :(=>), Expr(:quote, Symbol(sym)), Expr(:(=), esc(sym),
         Expr(:call, widget, esc(expr), Expr(:kw, :label, string(sym)))))
end

function map_block(block, symbols)
    lambda = Expr(:(->), Expr(:tuple, symbols...),
                  block)
    f = gensym()
    quote
        $f = $lambda
        ob = Observables.Observable{Any}($f($(map(s->:(observe($s)[]), symbols)...)))
        map!($f, ob, $(map(s->:(observe($s)), symbols)...))
        ob
    end
end

function symbols(bindings)
    map(x->x.args[1], bindings)
end

macro manipulate(expr)
    if expr.head != :for
        error("@manipulate syntax is @manipulate for ",
              " [<variable>=<domain>,]... <expression> end")
    end
    block = expr.args[2]
    if expr.args[1].head == :block
        bindings = expr.args[1].args
    else
        bindings = [expr.args[1]]
    end
    syms = symbols(bindings)

    widgets = map(make_widget, bindings)

    dict = Expr(:call, :OrderedDict, widgets...)
    quote
        local children = $dict
        local output = $(esc(map_block(block, syms)))
        local display = map(manipulateinnercontainer, output)
        local layout = t -> manipulateoutercontainer(map(center, values(t.children))..., t.display)
        Widget{:manipulate}(children, output=output, display=display, layout=layout)
    end
end

widget(x; kwargs...) = x
widget(x::Observable; label = nothing) =
    label === nothing ? x : Widget{:observable}(["label" => label], output = x, layout = t -> flex_row(t["label"], t.output))
widget(x::Range; kwargs...) = slider(x; kwargs...)
widget(x::AbstractVector; kwargs...) = togglebuttons(x; kwargs...)
widget(x::AbstractVector{<:Real}; kwargs...) = slider(x; kwargs...)
widget(x::Associative; kwargs...) = togglebuttons(x; kwargs...)
widget(x::Bool; kwargs...) = toggle(x; kwargs...)
widget(x::AbstractString; kwargs...) = textbox(; value=x, kwargs...)
widget(x::Real; kwargs...) = spinbox(value=Float64(x); kwargs...)
widget(x::Color; kwargs...) = colorpicker(x; kwargs...)
widget(x::Date; kwargs...) = datepicker(x; kwargs...)
widget(x::Dates.Time; kwargs...) = timepicker(x; kwargs...)

manipulateinnercontainer(T::WidgetTheme, el) = flex_row(el)
manipulateoutercontainer(T::WidgetTheme, args...) = dom"div"(args...)

center(w) = flex_row(w)
center(w::Widget) = w
center(w::Widget{:toggle}) = flex_row(w)
