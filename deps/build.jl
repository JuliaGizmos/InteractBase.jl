const _pkg_root = dirname(dirname(@__FILE__))
const _pkg_deps = joinpath(_pkg_root,"deps")
const _pkg_assets = joinpath(_pkg_root,"assets")

!isdir(_pkg_assets) && mkdir(_pkg_assets)

deps = [
    "https://use.fontawesome.com/releases/v5.0.7/js/all.js",
    "https://raw.githubusercontent.com/piever/InteractResources/master/highlight/prism.css",
    "https://raw.githubusercontent.com/piever/InteractResources/master/highlight/prism.js",
]

for dep in deps
    download(dep, joinpath(_pkg_assets, splitdir(dep)[2]))
end

using NodeJS
npm_path = joinpath(_pkg_assets, "npm")
mkpath(npm_path)
cd(npm_path) do
    npm = NodeJS.npm_cmd()
    run(`$npm install -y`)
    run(`$npm install -y katex`)
end
