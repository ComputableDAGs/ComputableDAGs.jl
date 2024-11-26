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
    "ke->ke",               # 1
    "kke->ke",              # 2
    "kkke->ke",             # 3
    "kkkke->ke",            # 4
    "kkkkke->ke",           # 5
    "kkkkkke->ke",          # 6
]

with_theme(theme_latexfonts()) do
    include("plotting/cpu_vs_gpu_exec.jl")
    include("plotting/f_exec_per_line.jl")
end
