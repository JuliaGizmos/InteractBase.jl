using WebIO, JSExpr

function latex(txt)
   (txt isa Observable) || (txt = Observable(txt))
   w = Scope(imports=[
           "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.9.0/katex.min.js",
           "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.9.0/katex.min.css"])

   w["value"] = txt

   onimport(w, @js function (k)
       this.k = k
       this.container = this.dom.querySelector("#container")
       k.render($(txt[]), this.container)
   end)

   onjs(w["value"], @js (txt) -> this.k.render(txt, this.container))

   w.dom = dom"div#container"()

   Widget(Val{:latex}(), w, "value")
end
