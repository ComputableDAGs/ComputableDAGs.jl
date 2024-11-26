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

function proc_n(s::String)
    s = replace(s, "e" => "e^-")
    s = replace(s, "k" => "γ")

    (prefix, suffix) = split(s, "->")
    k_count = count(c -> c == 'γ', prefix)

    if k_count > 1
        prefix = replace(prefix, r"γ+" => "γ^$k_count")
    end

    return k_count
end

SCATTERING_PROCESSES = [
    #"ke->ke",               # 1
    #"kke->ke",              # 2
    "kkke->ke",             # 3
    "kkkke->ke",            # 4
    #"kkkkke->ke",           # 5
]

with_theme(theme_latexfonts()) do
    #include("plotting/opt_progress.jl")
    #include("plotting/opt_progress_vs_flops.jl")
    #include("plotting/opt_progress_vs_flops_norm.jl")
    include("plotting/opt_progress_speedup.jl")
end
