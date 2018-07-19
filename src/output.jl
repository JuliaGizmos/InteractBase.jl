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
   counter = Observable(0)
   data = ["text" => value, "counter" => counter]
   scp = knockout(Node(:div), data,
      js"this.counter.subscribe(function (value) {alert(this.text())}, this)")
   Widget{:alert}(data; scope = scp, layout = scope)
end

widget(::Val{:alert}, args...; kwargs...) = alert(args...; kwargs...)

(wdg::Widget{:alert})(text = wdg["text"][]) = (wdg["text"][] = text; wdg["counter"][] += 1; return)
