import KaTeX

const autorender_min_js, katex_min_css, katex_min_js = joinpath.(KaTeX.assetsdir, KaTeX.assets)
const katex_fonts = joinpath.(KaTeX.fontsdir, readdir(KaTeX.fontsdir))

"""
`latex(txt)`

Render `txt` in LaTeX using KaTeX. Backslashes need to be escaped:
`latex("\\\\sum_{i=1}^{\\\\infty} e^i")`
"""
function latex(::WidgetTheme, txt)
    (txt isa AbstractObservable) || (txt = Observable(txt))
    w = Scope(imports=[
        katex_min_js,
        katex_min_css,
        katex_fonts... # This import also fails, not sure how to make it find fonts!
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

function autorender_latex(s::AbstractString)
    # This import fails!
    w = Scope(imports = [katex_min_css, katex_min_js, autorender_min_js])
    w.dom = s
    onimport(w, js"""
    function (katex, autorender) {
        document.addEventListener("DOMContentLoaded", function() {
            renderMathInElement(this.dom, {delimiters: [ // mind the order of delimiters(!?)
                {left: "\$\$", right: "\$\$", display: true},
                {left: "\$", right: "\$", display: false},
                {left: "\\[", right: "\\]", display: true},
                {left: "\\(", right: "\\)", display: false},
            ]});
        });
    }
    """)
    w
end
