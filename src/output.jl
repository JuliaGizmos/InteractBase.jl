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

function highlight(txt; language = "julia")
   (txt isa Observable) || (txt = Observable(txt))

    codeblock = WebIO.render(
      HTML("""
         <pre><code class="language-$language">
         $(txt[])
         </code></pre>
         """
      )
    )

    w = Scope(imports = [
        style_css,
        prism_js,
        prism_css,
    ])

    w["value"] = txt

    w.dom = codeblock

    Widget{:highlight}(scope = w, output = w["value"], layout = scope)
end
