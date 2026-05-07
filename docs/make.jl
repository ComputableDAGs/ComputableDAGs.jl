using Pkg

project_path = Base.Filesystem.joinpath(Base.Filesystem.dirname(Base.source_path()), "..")
Pkg.develop(; path = project_path)

using Documenter
using ComputableDAGs

pages = [
    "index.md",
    "Library" => [
        "Public" => "lib/public.md",
        "Task" => "lib/internals/tasks.md",
    ],
    "Contribution" => "contribution.md",
]

makedocs(;
    modules = [ComputableDAGs],
    checkdocs = :exports,
    authors = "Anton Reinhard",
    repo = Documenter.Remotes.GitHub("ComputableDAGs", "ComputableDAGs.jl"),
    sitename = "ComputableDAGs.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://ComputableDAGs.github.io/ComputableDAGs.jl",
        assets = String[],
    ),
    pages = pages,
)
deploydocs(; repo = "github.com/ComputableDAGs/ComputableDAGs.jl.git", push_preview = false)
