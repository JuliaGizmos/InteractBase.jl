using Documenter, InteractBase

makedocs(
    format = Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
    ),
    sitename = "InteractBase",
    authors = "Pietro Vertechi",
    pages = [
        "Introduction" => "index.md",
    ]
)

deploydocs(repo = "github.com/piever/InteractBase.jl.git")
