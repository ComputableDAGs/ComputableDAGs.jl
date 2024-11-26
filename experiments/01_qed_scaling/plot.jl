using Pkg: Pkg
Pkg.activate("$(@__DIR__)/../..")

using ComputableDAGs
using QEDFeynman
using QEDcore, QEDprocesses

using BenchmarkTools
using JLD2

using CairoMakie
using BenchmarkPlots
using LaTeXStrings

jsonfile = "$(@__DIR__)/data/bench.json"

include("$(@__DIR__)/../utils.jl")

plotpath = "$(@__DIR__)/plots"
if !isdir(plotpath)
    mkdir(plotpath)
end

_to_vec(s) = [s]

function proc_str(s::String)
    s = replace(s, "e" => "e^-")
    s = replace(s, "k" => "γ")

    (prefix, suffix) = split(s, "->")
    k_count = count(c -> c == 'γ', prefix)

    if k_count > 1
        prefix = replace(prefix, r"γ+" => "γ^$k_count")
    end

    return L"%$(k_count)"
end

SCATTERING_PROCESSES = [
    "ke->ke", "kke->ke", "kkke->ke", "kkkke->ke", "kkkkke->ke", "kkkkkke->ke", "kkkkkkke->ke", "kkkkkkkke->ke"
]

with_theme(theme_latexfonts()) do
    include("plotting/graph_gen.jl")
    include("plotting/f_gen.jl")
    include("plotting/f_exec.jl")
    include("plotting/f_exec_per_line.jl")
    include("plotting/f_gen_per_line.jl")
    include("plotting/graph_size.jl")
    include("plotting/graph_size_w_ratio.jl")
    include("plotting/compile_time.jl")
    include("plotting/gen_total.jl")
end
