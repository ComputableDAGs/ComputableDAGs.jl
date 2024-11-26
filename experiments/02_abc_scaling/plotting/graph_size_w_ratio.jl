# == Graph Size With Ratio ==
colors = Makie.wong_colors()

@load "data/bench.jld2"

data = Vector{Dict{Type,Float64}}()
for dict in getindex.(Ref(node_dicts), SCATTERING_PROCESSES)
    s = sum(values(dict))
    new_dict = Dict{Type,Float64}()
    for k in keys(dict)
        new_dict[k] = (dict[k] / s) * 100.0 # convert to % ratios
    end
    push!(data, new_dict)
end

f = Figure(; size=(600, 500))
ax = Axis(
    f[1, 1];
    yaxisposition=:right,
    ylabel="ratios of node types",
    limits=(nothing, (0, 100)),
    ygridvisible=false,
    yminorgridvisible=false,
    yminorticksvisible=true,
    yticks=([0, 50, 100], [L"0%", L"50%", L"100%"]),
    yminorticks=IntervalsBetween(5),
)
hidespines!(ax)
hidexdecorations!(ax)

categories = repeat(1:l, 6)
height = [
    [d[ComputableDAGs.DataTask] for d in data]
    [d[ComputeTaskABC_U] for d in data]
    [d[ComputeTaskABC_V] for d in data]
    [get(d, ComputeTaskABC_S1, zero(Float64)) for d in data]
    [d[ComputeTaskABC_S2] for d in data]
    [d[ComputeTaskABC_Sum] for d in data]
]
grp = vcat([[i for _ in 1:l] for i in 1:6]...)

barplot!(#
    ax,
    categories,
    height;
    stack=grp,
    color=colors[grp .+ 1],
)

data = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)
l = length(data)

ax2 = Axis(
    f[1, 1];
    xlabel="number of outgoing B-ons",
    ylabel="number of nodes in the CDAG",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
)
linkxaxes!(ax, ax2)

sc = scatter!(ax2, [(1:l)...], data; markersize=15)

# Legend
labels = ["Total", "Data", "U", "V", "S1", "S2", "Sum"]
elements = [
    sc
    [PolyElement(; polycolor=colors[i]) for i in 2:(length(labels))]
]
title = "Task Types"

Legend(f[2, 1], elements, labels, title; tellheight=true, tellwidth=false, orientation=:horizontal)

save(joinpath(plotpath, "graph_size_compton_w_ratio.pdf"), f)
