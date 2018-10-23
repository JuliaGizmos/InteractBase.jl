using WebIO, JSExpr

const katex_min_js = joinpath(@__DIR__, "..", "assets", "katex.min.js")

const katex_min_css = joinpath(@__DIR__, "..", "assets", "katex.min.css")

"""
`latex(txt)`

Render `txt` in LaTeX using KaTeX. Backslashes need to be escaped:
`latex("\\\\sum_{i=1}^{\\\\infty} e^i")`
"""
function latex(txt)
    (txt isa AbstractObservable) || (txt = Observable(txt))
    w = Scope(imports=[
        katex_min_js,
        katex_min_css
    ])

    w["value"] = txt

    onimport(w, @js function (k)
        this.k = k
        this.container = this.dom.querySelector("#container")
        k.render($(txt[]), this.container)
    end)

    onjs(w["value"], @js (txt) -> this.k.render(txt, this.container))

    w.dom = dom"div#container"()

    Widget{:latex}(scope = w, output = w["value"], layout = dom"div.field"∘Widgets.scope)
end

"""
`alert(text="")`

Creates a `Widget{:alert}`. To cause it to trigger an alert, do:

```julia
wdg = alert("Error!")
wdg()
```

Calling `wdg` with a string will set the alert message to that string before triggering the alert:

```julia
wdg = alert("Error!")
wdg("New error message!")
```

For the javascript to work, the widget needs to be part of the UI, even though it is not visible.
"""
function alert(text = ""; value = text)
    value isa AbstractObservable || (value = Observable(value))

    scp = WebIO.Scope()
    setobservable!(scp, "text", value)
    onjs(
        scp["text"],
        js"""function (value) {
            alert(value);
        }"""
    )
    Widget{:alert}(["text" => value]; scope = scp,
    layout = t -> node(:div, Widgets.scope(t), style = Dict("visible" => false)))
end

widget(::Val{:alert}, args...; kwargs...) = alert(args...; kwargs...)

(wdg::Widget{:alert})(text = wdg["text"][]) = (wdg["text"][] = text; return)

"""
`confirm([f,] text="")`

Creates a `Widget{:confirm}`. To cause it to trigger a confirmation dialogue, do:

```julia
wdg = confirm([f,] "Are you sure you want to unsubscribe?")
wdg()
```

`observe(wdg)` is a `Observable{Bool}` and is set to `true` if the user clicks on "OK" in the dialogue,
or to false if the user closes the dialogue or clicks on "Cancel". When `observe(wdg)` is set, the function `f`
will be called with that value.

Calling `wdg` with a string and/or a function will set the confirmation message and/or the callback function:

```julia
wdg = confirm("Are you sure you want to unsubscribe?")
wdg("File exists, overwrite?") do x
   x ? print("Overwriting") : print("Aborting")
end
```

For the javascript to work, the widget needs to be part of the UI, even though it is not visible.
"""
function confirm(fct::Function = x -> nothing, text::AbstractString = "")
    text isa AbstractObservable || (text = Observable(text))

    scp = WebIO.Scope()
    setobservable!(scp, "text", text)
    value = Observable(scp, "value", false)
    onjs(
        scp["text"],
        @js function (txt)
            $value[] = confirm(txt)
        end
    )
    wdg = Widget{:confirm}(["text" => text, "function" => fct]; scope = scp, output = value,
    layout = t -> node(:div, Widgets.scope(t), style = Dict("visible" => false)))
    on(x -> wdg["function"](x), value)
    wdg
end

confirm(text::AbstractString, fct::Function = x -> nothing) = confirm(fct, text)

widget(::Val{:confirm}, args...; kwargs...) = confirm(args...; kwargs...)

function (wdg::Widget{:confirm})(fct::Function = wdg["function"], text::AbstractString = wdg["text"][])
   wdg["function"] = fct
   wdg["text"][] = text
   return
end

(wdg::Widget{:confirm})(text::AbstractString, fct::Function = wdg["function"]) = wdg(fct, text)

"""
`highlight(txt; language = "julia")`

`language` syntax highlighting for `txt`.
"""
function highlight(txt; language = "julia")
    (txt isa AbstractObservable) || (txt = Observable(txt))

    s = "code"*randstring(16)

    w = Scope(imports = [
       highlight_css,
       prism_js,
       prism_css,
    ])

    w["value"] = txt

    w.dom = node(
        :div,
        node(
            :pre,
            node(:code, className = "language-$language", attributes = Dict("id"=>s))
        ),
        className = "content"
    )

    onimport(w, js"""
        function (p) {
            var code = document.getElementById($s);
            code.innerHTML = $(txt[]);
            Prism.highlightElement(code);
        }
    """
    )

    onjs(w["value"], js"""
      function (val){
          var code = document.getElementById($s);
          code.innerHTML = val
          Prism.highlightElement(code)
      }
   """)

    Widget{:highlight}(scope = w, output = w["value"], layout = Widgets.scope)
end

widget(::Val{:highlight}, args...; kwargs...) = highlight(args...; kwargs...)

function notifications(::WidgetTheme, v=[]; container = div, wrap = identity, layout = (v...)->container((wrap(el) for el in v)...), className = "")
    wdg = Widget{:notifications}(output = Observable{Any}(v))
    className = mergeclasses(className, "notification")
    wdg[:list] = map(observe(wdg)) do t
        list = t
        function create_item(ind, el)
            btn = button(className = "delete")
            on(observe(btn)) do x
                deleteat!(list, ind)
                observe(wdg)[] = observe(wdg)[]
            end
            div(btn, className = className, el)
        end
        [create_item(ind, el) for (ind, el) in enumerate(list)]
    end
    scope!(wdg, slap_design!(Scope()))
    Widgets.scope(wdg).dom = map(v -> layout(v...), wdg[:list])
    @layout! wdg Widgets.scope(_)
end

widget(::Val{:notifications}, args...; kwargs...) = notifications(args...; kwargs...)

"""
`notifications(v=[]; layout = node(:div))`

Display elements of `v` inside notification boxes that can be closed with a close button.
The elements are laid out according to `layout`.
`observe` on this widget returns the observable of the list of elements that have not bein deleted.
"""
notifications(args...; kwargs...) = notifications(gettheme(), args...; kwargs...)

"""
`accordion(options; multiple = true)`

Display `options` in an `accordion` menu. `options` is an `AbstractDict` whose
keys represent the labels and whose values represent what is shown in each entry.

`options` can be an `Observable`, in which case the `accordion` updates as soon as
`options` changes.
"""
function accordion(::WidgetTheme, options::Observable;
    multiple = true, value = nothing, index = value, key = Some(nothing))

    vals2idxs = map(Vals2Idxs∘collect∘_keys, options)
    p = initvalueindex(key, index, vals2idxs, rev = true, multiple = multiple)
    key, index = p.first, p.second

    option_array = map(x -> [OrderedDict("label" => key, "i" => i, "content" => stringmime(MIME"text/html"(), WebIO.render(val))) for (i, (key, val)) in enumerate(x)], options)

    onClick = multiple ? js"function (i) {this.index.indexOf(i) > -1 ? this.index.remove(i) : this.index.push(i)}" :
        js"function (i) {this.index(i)}"

    isactive = multiple ? "\$root.index.indexOf(i) > -1" : "\$root.index() == i"
    template = dom"section.accordions"(attributes = Dict("data-bind" => "foreach: options_js"),
        node(:article, className="accordion", attributes = Dict("data-bind" => "css: {'is-active' : $isactive}", ))(
            dom"div.accordion-header.toggle"(dom"p"(attributes = Dict("data-bind" => "html: label")), attributes = Dict("data-bind" => "click: function () {\$root.onClick(i)}")),
            dom"div.accordion-body"(dom"div.accordion-content"(attributes = Dict("data-bind" => "html: content")))
        )
    )
    scp = knockout(template, ["index" => index, "options_js" => option_array], methods = Dict("onClick" => onClick))
    slap_design!(scp)
    Widget{:accordion}(["index" => index, "key" => key, "options" => options]; scope = scp, output = index, layout = Widgets.scope)
end

accordion(T::WidgetTheme, options; kwargs...) = accordion(T, Observable{Any}(options); kwargs...)

"""
`togglecontent(content, value::Union{Bool, Observable}=false; label)`

A toggle switch that, when activated, displays `content`
e.g. `togglecontent(checkbox("Yes, I am sure"), false, label="Are you sure?")`
"""
function togglecontent(::WidgetTheme, content, args...; skip = 0em, vskip = skip, kwargs...)
    btn = toggle(gettheme(), args...; kwargs...)
    Widgets.scope(btn).dom =  vbox(
        Widgets.scope(btn).dom,
        node(:div,
            content,
            attributes = Dict("data-bind" => "visible: value")
        )
    )
    Widget{:togglecontent}(btn)
end

"""
`mask(options; index, key)`

Only display the `index`-th element of `options`. If `options` is a `AbstractDict`, it is possible to specify
which option to show using `key`. `options` can be a `Observable`, in which case `mask` updates automatically.
Use `index=0` or `key = nothing` to not have any selected option.

## Examples

```julia
wdg = mask(OrderedDict("plot" => plot(rand(10)), "scatter" => scatter(rand(10))), index = 1)
wdg = mask(OrderedDict("plot" => plot(rand(10)), "scatter" => scatter(rand(10))), key = "plot")
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
function mask(options; value = nothing, index = value, key = Some(nothing), multiple = false)

    options isa AbstractObservable || (options = Observable{Any}(options))
    vals2idxs = map(Vals2Idxs∘collect∘_keys, options)
    p = initvalueindex(key, index, vals2idxs, rev = true, multiple = multiple)
    key, index = p.first, p.second

    ui = map(options) do val
        v = _values(val)
        nodes = (node(:div, el,  attributes = Dict("data-bind" => "visible: index() == $i")) for (i, el) in enumerate(v))
        knockout(node(:div, nodes...), ["index" => index])
    end
    Widget{:mask}(["index" => index, "key" => key, "options" => options];
        output = index, layout = t -> ui)
end


@deprecate tabulator(T::WidgetTheme, keys, vals; kwargs...) tabulator(T, OrderedDict(zip(keys, vals)); kwargs...)

"""
`tabulator(options::AbstractDict; index, key)`

Creates a set of toggle buttons whose labels are the keys of options. Displays the value of the selected option underneath.
Use `index::Int` to select which should be the index of the initial option, or `key::String`.
The output is the selected `index`. Use `index=0` to not have any selected option.

## Examples

```julia
tabulator(OrderedDict("plot" => plot(rand(10)), "scatter" => scatter(rand(10))), index = 1)
tabulator(OrderedDict("plot" => plot(rand(10)), "scatter" => scatter(rand(10))), key = "plot")
```

`tabulator(values::AbstractArray; kwargs...)`

`tabulator` with labels `values`
see `tabulator(options::AbstractDict; ...)` for more details

```
tabulator(options::Observable; kwargs...)
```

Tabulator whose `options` are a given `Observable`. Set the `Observable` to some other
value to update the options in real time.

## Examples

```julia
options = Observable(["a", "b", "c"])
wdg = tabulator(options)
options[] = ["c", "d", "e"]
```

Note that the `options` can be modified from the widget directly:

```julia
wdg[:options][] = ["c", "d", "e"]
```
"""
function tabulator(T::WidgetTheme, options; navbar = togglebuttons, skip = 1em, vskip = skip, value = nothing, index = value, key = Some(nothing),  kwargs...)
    options isa AbstractObservable || (options = Observable{Any}(options))
    vals2idxs = map(Vals2Idxs∘collect∘_keys, options)
    p = initvalueindex(key, index, vals2idxs, rev = true)
    key, index = p.first, p.second

    d = map(t -> OrderedDict(zip(parent(t), 1:length(parent(t)))), vals2idxs)
    buttons = navbar(T, d; index = index, readout = false, kwargs...)
    content = mask(options; index = index)

    layout = t -> div(t[:buttons], CSSUtil.vskip(vskip), t[:content])
    Widget{:tabulator}(["index" => index, "key" => key, "buttons" => buttons, "content" => content, "options" => options];
        output = index, layout = layout)
end
