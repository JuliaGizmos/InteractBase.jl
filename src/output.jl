using WebIO, JSExpr

function katex(txt)
   (txt isa Observable) || (txt = Observable(txt))
   w = Scope(imports=[
           "/pkg/InteractBase/npm/node_modules/katex/dist/katex.min.js",
           "/pkg/InteractBase/npm/node_modules/katex/dist/katex.min.css"])

   w["value"] = txt

   onimport(w, @js function (k)
       this.k = k
       this.container = this.dom.querySelector("#container")
       k.render($(txt[]), this.container)
   end)

   onjs(w["value"], @js (txt) -> this.k.render(txt, this.container))

   w.dom = dom"div#container"()

   Widget(Val{:katex}(), w, "value")
end
