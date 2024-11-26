# == Function Execution Time Per Line ==
colors = Makie.wong_colors()

data = copy(result["f_exec"])
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data_x = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)
for i in eachindex(data)
    data[i] = data[i] ./ data_x[i]
end
data = median.(data)

f = Figure()
ax = Axis(
    f[1, 1];
    yaxisposition=:right,
    yminorgridvisible=false,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    ylabel="execution time average per node",
    limits=(nothing, _find_y_lims(data)),
    yticks=(yticks1, yticks2),
)
hidespines!(ax)
hidexdecorations!(ax)

barplot!(ax, [(1:l)...], data; color=colors[2])

@load "data/bench.jld2"

data = result["f_exec"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = median.(data)

ax2 = Axis(
    f[1, 1];
    xlabel="number of outgoing B-ons",
    ylabel="function execution time",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)
linkxaxes!(ax, ax2)

scatter!(ax2, [(1:l)...], data; markersize=12)

save(joinpath(plotpath, "f_exec_compton_per_line.pdf"), f)
