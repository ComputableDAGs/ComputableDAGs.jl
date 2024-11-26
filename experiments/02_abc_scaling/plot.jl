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
    (prefix, suffix) = split(s, "->")
    b_count = count(c -> c == 'B', suffix)

    if b_count > 1
        prefix = replace(prefix, r"B+" => "B^$b_count")
    end

    return L"%$(b_count)"
end

SCATTERING_PROCESSES = ["AB->AB", "AB->ABBB", "AB->ABBBBB", "AB->ABBBBBBB", "AB->ABBBBBBBBB"]

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
