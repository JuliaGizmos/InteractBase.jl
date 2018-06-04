using WebIO, JSExpr

function latex(txt)
   w = Scope(imports=[
           "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.10.0-alpha/katex.min.js",
           "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.10.0-alpha/katex.min.css"])

   w["text"][] = txt

   onimport(w, @js function (k)
       this.k = k
       this.container = this.dom.querySelector("#container")
       k.render($txt, this.container)
   end)

   onjs(w["text"], @js (txt) -> this.k.render(txt, this.container))

   w.dom = dom"div#container"()

   w
end
