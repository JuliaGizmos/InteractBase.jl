export @manipulate, widget

function make_widget(binding)
    if binding.head != :(=)
        error("@manipulate syntax error.")
    end
    sym, expr = binding.args
    Expr(:(=), esc(sym),
         Expr(:call, widget, esc(expr), string(sym)))
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
    quote
        manipulateoutercontainer($(widgets...), manipulateinnercontainer($(esc(map_block(block, syms)))))
    end
end

widget(x, label="") = x
widget(x::Observable, label="") = Widget{:observable}(["label" => label], output = x, layout = t -> flex_row(t["label"], t.output))
widget(x::Range, label="") = slider(x; label=label)
widget(x::AbstractVector, label="") = togglebuttons(x, label=label) # slider(x; label=label) ?
widget(x::Associative, label="") = togglebuttons(x, label=label)
widget(x::Bool, label="") = wrap(toggle(x, label=label), flex_row)
widget(x::AbstractString, label="") = textbox(value=x, label=label)
widget(x::Real, label="") = spinbox(value=Float64(x), label=label)
widget(x::Color, label="") = colorpicker(x, label=label)
widget(x::Date, label="") = datepicker(x, label=label)
widget(x::Dates.Time, label="") = timepicker(x, label=label)

manipulateinnercontainer(T::WidgetTheme, el) = flex_row(el)
manipulateoutercontainer(T::WidgetTheme, args...) = dom"div"(args...)
