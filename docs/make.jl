using Documenter, InteractBase, Literate
src = joinpath(@__DIR__, "src")
Literate.markdown(joinpath(src, "tutorial.jl"), src, codefence = "```julia" => "```")

makedocs(
    format = :html,
    sitename = "InteractBase",
    authors = "Pietro Vertechi",
    pages = [
        "Introduction" => "index.md",
        "Tutorial" => "tutorial.md",
        "API reference" => "api_reference.md",
    ]
)

deploydocs(
    repo = "github.com/piever/InteractBase.jl.git",
    target = "build",
    julia  = "0.6",
    osname = "linux",
    deps   = nothing,
    make   = nothing
)
