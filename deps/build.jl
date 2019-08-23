const _pkg_root = dirname(dirname(@__FILE__))
const _pkg_deps = joinpath(_pkg_root,"deps")
const _pkg_assets = joinpath(_pkg_root,"assets")

!isdir(_pkg_assets) && mkdir(_pkg_assets)

deps = [
    "https://use.fontawesome.com/releases/v5.0.7/js/all.js",
    "https://cdn.jsdelivr.net/gh/piever/InteractResources@0.1.0/highlight/prism.css",
    "https://cdn.jsdelivr.net/gh/piever/InteractResources@0.1.0/highlight/prism.js",
    "https://cdnjs.cloudflare.com/ajax/libs/noUiSlider/11.1.0/nouislider.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/noUiSlider/11.1.0/nouislider.min.css",
    "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.9.0/katex.min.js",
    "https://cdnjs.cloudflare.com/ajax/libs/KaTeX/0.9.0/katex.min.css"
]

for dep in deps
    download(dep, joinpath(_pkg_assets, splitdir(dep)[2]))
end
