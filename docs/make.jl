using Pkg

project_path = Base.Filesystem.joinpath(Base.Filesystem.dirname(Base.source_path()), "..")
Pkg.develop(; path = project_path)

using Documenter
using ComputableDAGs

pages = [
    "index.md",
    "Manual" => "manual.md",
    "Library" => [
        "Public" => "lib/public.md",
        "Graph" => "lib/internals/graph.md",
        "Node" => "lib/internals/node.md",
        "Task" => "lib/internals/task.md",
        "Operation" => "lib/internals/operation.md",
        "Models" => "lib/internals/models.md",
        "Diff" => "lib/internals/diff.md",
        "Utility" => "lib/internals/utility.md",
        "Code Generation" => "lib/internals/code_gen.md",
        "Devices" => "lib/internals/devices.md",
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
