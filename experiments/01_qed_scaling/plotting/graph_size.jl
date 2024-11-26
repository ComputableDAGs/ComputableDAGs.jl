# == Graph Size ==
@load "data/bench.jld2"

colors = Makie.to_colormap(:tab10)

data = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)
l = length(data)

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel="number of incoming photons",
    ylabel="number of nodes in the CDAG",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
)

sc = scatter!(ax, [(1:l)...], data)

save(joinpath(plotpath, "graph_size_compton.pdf"), f)
