using KaTeX: assetsdir, assets

const katex_min_js = joinpath(assetsdir, "katex.min.js")

const katex_min_css = joinpath(assetsdir, "katex.min.css")

"""
`latex(txt)`

Render `txt` in LaTeX using KaTeX. Backslashes need to be escaped:
`latex("\\\\sum_{i=1}^{\\\\infty} e^i")`
"""
function latex(::WidgetTheme, txt)
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

    Widget{:latex}(scope = w, output = w["value"], layout = node(:div, className = "interact-widget")∘Widgets.scope)
end
