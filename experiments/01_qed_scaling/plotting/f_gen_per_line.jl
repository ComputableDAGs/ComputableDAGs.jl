# == Function Generation Time per Line ==
@load "data/bench.jld2"

data = copy(result["f_gen"])
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
    xlabel="number of incoming photons",
    ylabel="function generation time\naveraged over number of nodes",
    limits=(nothing, (1e4, 1e6)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

scatter!(ax, [(1:l)...], data)

save(joinpath(plotpath, "f_gen_per_line.pdf"), f)
