using Pkg

project_path = Base.Filesystem.joinpath(Base.Filesystem.dirname(Base.source_path()), "..")
Pkg.develop(; path = project_path)

using Documenter
using Literate
using ComputableDAGs

# setup examples using Literate.jl
literate_paths = [
    (
        Base.Filesystem.joinpath(project_path, "docs/src/examples/fibonacci.jl"),
        Base.Filesystem.joinpath(project_path, "docs/src/examples/"),
    ),
]

for (file, output_dir) in literate_paths
    Literate.markdown(file, output_dir; documenter = true)
    Literate.notebook(file, output_dir)
end

pages = [
    "index.md",
    "Manual" => "manual.md",
    "Examples" => [
        "Fibonacci" => "examples/fibonacci.md",
    ],
    "Library" => [
        "Public" => "lib/public.md",
        "Graph" => "lib/internals/graph.md",
        "Node" => "lib/internals/node.md",
        "Task" => "lib/internals/task.md",
        "Properties" => "lib/internals/properties.md",
        "Operation" => "lib/internals/operation.md",
        "Estimation" => "lib/internals/estimator.md",
        "Optimization" => "lib/internals/optimization.md",
        "Models" => "lib/internals/models.md",
        "Diff" => "lib/internals/diff.md",
        "Scheduler" => "lib/internals/scheduler.md",
        "Code Generation" => "lib/internals/code_gen.md",
        "Devices" => "lib/internals/devices.md",
        "Utility" => "lib/internals/utility.md",
        "KernelAbstractions Extension" => "lib/internals/ka_extension.md",
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
