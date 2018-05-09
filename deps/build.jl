const _pkg_root = dirname(dirname(@__FILE__))
const _pkg_deps = joinpath(_pkg_root,"deps")
const _pkg_assets = joinpath(_pkg_root,"assets")

!isdir(_pkg_assets) && mkdir(_pkg_assets)

download("https://fonts.googleapis.com/css?family=Roboto:300,300italic,700,700italic", joinpath(_pkg_assets,"fonts.css"))
download("https://cdn.rawgit.com/necolas/normalize.css/master/normalize.css",  joinpath(_pkg_assets,"normalize.css"))
download("https://cdn.rawgit.com/milligram/milligram/master/dist/milligram.min.css", joinpath(_pkg_assets,"milligram.min.css"))
