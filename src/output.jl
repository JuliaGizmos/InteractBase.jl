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

   Widget{:latex}(w, "value")
end
