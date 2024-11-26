# == Graph Generation Time ==
result = BenchmarkTools.load(jsonfile)[1]
data = result["graph_gen"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = median.(data)

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel="number of outgoing B-ons",
    ylabel="graph generation time",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

scatter!(ax, [(1:l)...], data; markersize=15)

save(joinpath(plotpath, "graph_gen_compton.pdf"), f)
