using Pkg

project_path = Base.Filesystem.joinpath(Base.Filesystem.dirname(Base.source_path()), "..")
Pkg.develop(; path = project_path)

using Documenter
using ComputableDAGs

pages = [
    "index.md",
    "Library" => [
        "Public" => "lib/public.md",
        "Tasks" => "lib/internals/tasks.md",
        "Nodes" => "lib/internals/nodes.md",
        "Computable DAG" => "lib/internals/computable_dags.md",
        "Instructions" => "lib/internals/instructions.md",
        "Devices" => "lib/internals/devices.md",
        "Machines" => "lib/internals/machines.md",
        "Device Managers" => "lib/internals/device_managers.md",
        "Tapes" => "lib/internals/tapes.md",
        "Utility" => "lib/internals/utility.md",
    ],
    "Contribution" => "contribution.md",
]

makedocs(;
    modules = [ComputableDAGs],
    checkdocs = :all,
    linkcheck = true,
    warnonly = [:linkcheck],
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
