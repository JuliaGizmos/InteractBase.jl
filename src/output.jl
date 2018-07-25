using WebIO, JSExpr

const katex_min_js = joinpath(@__DIR__, "..", "assets",
                             "npm", "node_modules", "katex",
                             "dist", "katex.min.js")

const katex_min_css = joinpath(@__DIR__, "..", "assets",
                             "npm", "node_modules", "katex",
                             "dist", "katex.min.css")

"""
`latex(txt)`

Render `txt` in LaTeX using KaTeX. Backslashes need to be escaped:
`latex("\\\\sum_{i=1}^{\\\\infty} e^i")`
"""
function latex(txt)
   (txt isa Observable) || (txt = Observable(txt))
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

   Widget{:latex}(scope = w, output = w["value"], layout = t -> dom"div.field"(t.scope))
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
   value isa Observable || (value = Observable(value))

   scp = WebIO.Scope()
   setobservable!(scp, "text", value)
   onjs(scp["text"], js"""function (value) {
      alert(value);
      }"""
   )
   Widget{:alert}(["text" => value]; scope = scp,
      layout = t -> Node(:div, scope(t), style = Dict("visible" => false)))
end

widget(::Val{:alert}, args...; kwargs...) = alert(args...; kwargs...)

(wdg::Widget{:alert})(text = wdg["text"][]) = (wdg["text"][] = text; return)

"""
`highlight(txt; language = "julia")`

`language` syntax highlighting for `txt`.
"""
function highlight(txt; language = "julia")
    (txt isa Observable) || (txt = Observable(txt))

    s = "code"*randstring(16)

    w = Scope(imports = [
       style_css,
       prism_js,
       prism_css,
    ])

    w["value"] = txt

    w.dom = Node(
        :div,
        Node(
            :pre,
            Node(:code, className = "language-$language", attributes = Dict("id"=>s))
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

    Widget{:highlight}(scope = w, output = w["value"], layout = scope)
end

widget(::Val{:highlight}, args...; kwargs...) = highlight(args...; kwargs...)

@widget wdg function notifications(::WidgetTheme, v=[]; layout = div, className = "")
    className = mergeclasses(className, "notification")
    @output! wdg Observable{Any}(v)
    :list = begin
        list = $(_.output)
        function create_item(ind, el)
            btn = button(className = "delete")
            on(observe(btn)) do x
                deleteat!(list, ind)
                _.output[] = _.output[]
            end
            div(btn, className = className, el)
        end
        [create_item(ind, el) for (ind, el) in enumerate(list)]
    end
    wdg.scope = Scope() |> slap_design!
    wdg.scope.dom = map(layout, wdg[:list])
    @layout! wdg _.scope
end

"""
`notifications(v=[]; layout = Node(:div))`

Display elements of `v` inside notification boxes that can be closed with a close button.
The elements are laid out according to `layout`.
`observe` on this widget returns the observable of the list of elements that have not bein deleted.
"""
notifications(args...; kwargs...) = notifications(gettheme(), args...; kwargs...)

function accordion(::WidgetTheme, options::Associative;
    value = Int[], index = value)

    (index isa Observable) || (index = Observable(index))
    onClick = js"""
    function (i){
        i in this.index() ? this.index.remove(i) : this.index.push(i);
    }
    """
    template = dom"section.accordions"(
        [Node(:article, className="accordion", attributes = Dict("data-bind" => "css: {'is-active' : $i in index()}", ))(
            dom"div.accordion-header.toggle"(dom"p"(label), attributes = Dict("data-bind" => "click: function () {onClick($i)}")),
            dom"div.accordion-body"(dom"div.accordion-content"(content))
        ) for (i, (label, content)) in enumerate(options)]...
    )
    ui = knockout(template, ["index" => index], methods = Dict("onClick" => onClick))

    slap_design!(ui)
end
