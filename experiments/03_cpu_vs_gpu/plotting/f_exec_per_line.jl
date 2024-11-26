# == Function Execution Time Per Line ==
colors = Makie.wong_colors()

data = copy(result)
l = length(data)
data_cpu = getindex.(Ref(data), SCATTERING_PROCESSES[1:l])
data_cpu = getindex.(data_cpu, Ref("CPU"))
data_cpu = getfield.(data_cpu, :times)
data_cpu = median.(data_cpu)

data_gpu = getindex.(Ref(data), SCATTERING_PROCESSES[1:l])
data_gpu = getindex.(data_gpu, Ref("GPU"))
data_gpu = getfield.(data_gpu, :times)
data_gpu = median.(data_gpu)


data_x = getfield.(getindex.(Ref(graph_props), SCATTERING_PROCESSES), :number_of_nodes)

data_cpu_pn = similar(data_cpu)
data_gpu_pn = similar(data_gpu)

for i in eachindex(data_cpu)
    data_cpu_pn[i] = data_cpu[i] ./ data_x[i]
end

for i in eachindex(data_gpu)
    data_gpu_pn[i] = data_gpu[i] ./ data_x[i]
end

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel = "number of incoming photons",
    ylabel = "execution time",
    limits = (nothing, _find_y_lims(vcat(data_cpu, data_gpu, data_cpu_pn, data_gpu_pn))),
    yminorgridvisible = true,
    yminorticksvisible = true,
    yminorticks = IntervalsBetween(10),
    yscale = log10,
    xticks = ([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks = (yticks1, yticks2),
)

sc_cpu = scatter!(
    ax,
    [(1:l)...],
    data_cpu;
    color = colors[1],
    markersize = 12
)

sc_gpu = scatter!(
    ax,
    [(1:l)...],
    data_gpu;
    color = colors[2],
    markersize = 12
)

sc_cpu_pn = scatter!(
    ax,
    [(1:l)...],
    data_cpu_pn;
    color = colors[3],
    marker = :star5,
    markersize = 12
)

sc_gpu_pn = scatter!(
    ax,
    [(1:l)...],
    data_gpu_pn;
    color = colors[4],
    marker = :star5,
    markersize = 12
)

# Legend
labels = ["CPU Time", "GPU Time", "CPU Time per Node", "GPU Time per Node"]
elements = [sc_cpu, sc_gpu, sc_cpu_pn, sc_gpu_pn]

Legend(f[1, 1], elements, labels; tellheight = false, tellwidth = false, margin = (10, 10, 10, 10), halign = :left, valign = :top)

save(joinpath(plotpath, "f_exec_compton_per_node.pdf"), f)
