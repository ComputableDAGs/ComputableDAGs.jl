# == Total Generation Time as Stacked Bars ==
# graph gen times
result = BenchmarkTools.load(jsonfile)[1]
data_graph_gen = result["graph_gen"]
l = length(data_graph_gen)
data_graph_gen = getfield.(getindex.(Ref(data_graph_gen), SCATTERING_PROCESSES[1:l]), :times)
data_graph_gen = median.(data_graph_gen)

# function gen times
@load "data/bench.jld2"

data_fgen = result["f_gen"]
l = length(data_fgen)
data_fgen = getfield.(getindex.(Ref(data_fgen), SCATTERING_PROCESSES[1:l]), :times)
data_fgen = median.(data_fgen)

# function  compile time
l = length(comp_times)
data_compile = getindex.(Ref(comp_times), SCATTERING_PROCESSES[1:l])
for i in eachindex(data_compile)
    data_compile[i] = data_compile[i] *= 1e9 # convert to nanoseconds
end
data_compile = median.(data_compile)
data_graph_gen = data_graph_gen[1:l]
data_fgen = data_fgen[1:l]

# sum
data_sum = data_compile .+ data_graph_gen .+ data_fgen

# plot
f = Figure()

ax = Axis(
    f[1, 1];
    xlabel="number of outgoing B-ons",
    ylabel="time",
    limits=(nothing, _find_y_lims([data_sum, data_compile, data_graph_gen, data_fgen])),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

sc_sum = scatter!(ax, [(1:l)...], data_sum; markersize=20, marker=:star5)
sc_compile = scatter!(ax, [(1:l)...], data_compile)
sc_graph_gen = scatter!(ax, [(1:l)...], data_graph_gen)
sc_fgen = scatter!(ax, [(1:l)...], data_fgen)

# Legend
labels = ["Total Time", "Function Compilation", "Function Generation", "CDAG Generation"]
elements = [sc_sum, sc_compile, sc_fgen, sc_graph_gen]

Legend(f[1, 1], elements, labels; tellheight=false, tellwidth=false, margin=(10, 10, 10, 10), halign=:left, valign=:top)

save(joinpath(plotpath, "generation_times_total.pdf"), f)
