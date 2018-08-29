export @manipulate, widget

function make_widget(binding)
    if binding.head != :(=)
        error("@manipulate syntax error.")
    end
    sym, expr = binding.args
    Expr(:call, :(=>), Expr(:quote, Symbol(sym)), Expr(:(=), esc(sym),
         Expr(:call, widget, esc(expr), Expr(:kw, :label, string(sym)))))
end

function map_block(block, symbols, throttle = nothing)
    lambda = Expr(:(->), Expr(:tuple, symbols...),
                  block)
    f = gensym()

    get_obs(wdg, throttle::Nothing = nothing) = :(observe($wdg))
    get_obs(wdg, throttle) = :(InteractBase.throttle($throttle, $(get_obs(wdg))))
    quote
        $f = $lambda
        ob = Observables.Observable{Any}($f($(map(s->:(observe($s)[]), symbols)...)))
        map!($f, ob, $(get_obs.(symbols, throttle)...))
        ob
    end
end

function symbols(bindings)
    map(x->x.args[1], bindings)
end

"""
`@manipulate expr`

The @manipulate macro lets you play with any expression using widgets. `expr` needs to be a `for` loop. The `for` loop variable
are converted to widgets using the [`widget`](@ref) function (ranges become `slider`, lists of options become `togglebuttons`, etc...).
The `for` loop body is displayed beneath the widgets and automatically updated as soon as the widgets change value.

Use `throttle = df` to only update the output after a small time interval `dt` (useful if the update is costly as it prevents
multiple updates when moving for example a slider).

## Examples

```julia
using Colors

@manipulate for r = 0:.05:1, g = 0:.05:1, b = 0:.05:1
    HTML(string("<div style='color:#", hex(RGB(r,g,b)), "'>Color me</div>"))
end

@manipulate throttle = 0.1 for r = 0:.05:1, g = 0:.05:1, b = 0:.05:1
    HTML(string("<div style='color:#", hex(RGB(r,g,b)), "'>Color me</div>"))
end
```

[`@layout!`](@ref) can be used to adjust the layout of a manipulate block:

```julia
using Interact

ui = @manipulate throttle = 0.1 for r = 0:.05:1, g = 0:.05:1, b = 0:.05:1
    HTML(string("<div style='color:#", hex(RGB(r,g,b)), "'>Color me</div>"))
end
@layout! ui dom"div"(observe(_), vskip(2em), :r, :g, :b)
ui
```
"""
macro manipulate(args...)
    n = length(args)
    @assert 1 <= n <= 2
    expr = args[n]
    throttle = n == 2 ? args[1].args[2] : nothing

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
        local output = $(esc(map_block(block, syms, throttle)))
        local layout = t -> node(:div, map(center, values(components(t)))..., map(center, output))
        Widget{:manipulate}(children, output=output, layout=layout)
    end
end

"""
`widget(args...; kwargs...)`

Automatically convert Julia types into appropriate widgets. `kwargs` are passed to the
more specific widget function.

## Examples

```julia
map(display, [
    widget(1:10),                 # Slider
    widget(false),                # Checkbox
    widget("text"),               # Textbox
    widget(1.1),                  # Spinbox
    widget([:on, :off]),          # Toggle Buttons
    widget(Dict("π" => float(π), "τ" => 2π)),
    widget(colorant"red"),        # Color picker
    widget(Dates.today()),        # Date picker
    widget(Dates.Time()),         # Time picker
    ]);
```
"""
function widget end

@deprecate widget(x, label) widget(x, label = label)

widget(x; kwargs...) = x
widget(x::Observable; label = nothing) =
    label === nothing ? x : Widget{:observable}(["label" => label], output = x, layout = t -> flex_row(t["label"], t.output))
widget(x::AbstractRange; kwargs...) = slider(x; kwargs...)
widget(x::AbstractVector; kwargs...) = togglebuttons(x; kwargs...)
widget(x::AbstractVector{<:Real}; kwargs...) = slider(x; kwargs...)
widget(x::AbstractVector{Bool}; kwargs...) = togglebuttons(x; kwargs...)
widget(x::AbstractDict; kwargs...) = togglebuttons(x; kwargs...)
widget(x::Bool; kwargs...) = toggle(x; kwargs...)
widget(x::AbstractString; kwargs...) = textbox(; value=x, kwargs...)
widget(x::Real; kwargs...) = spinbox(; value=Float64(x), kwargs...)
widget(x::Color; kwargs...) = colorpicker(x; kwargs...)
widget(x::Date; kwargs...) = datepicker(x; kwargs...)
widget(x::Dates.Time; kwargs...) = timepicker(x; kwargs...)

center(w) = flex_row(w)
center(w::Widget) = w
center(w::Widget{:toggle}) = flex_row(w)
