# == Function Execution Time CPU/GPU==
@load "data/bench_o3.jld2"     # N, result, graph_props

colors = Makie.wong_colors()

data = result

l = length(data)

data = getindex.(Ref(data), SCATTERING_PROCESSES[1:l])

data_cpu_unopt = getindex.(getindex.(data, "CPU"), "unoptimized")
data_gpu_unopt = getindex.(getindex.(data, "GPU"), "unoptimized")
data_cpu_opt = getindex.(getindex.(data, "CPU"), "optimized")
data_gpu_opt = getindex.(getindex.(data, "GPU"), "optimized")

opt_time = getindex.(data, "OPTIM")
opt_time = getfield.(opt_time, :times)
opt_time = median.(opt_time)

data_cpu_unopt = getfield.(data_cpu_unopt, :times)
data_cpu_unopt = median.(data_cpu_unopt)
data_cpu_opt = getfield.(data_cpu_opt, :times)
data_cpu_opt = median.(data_cpu_opt)

data_cpu_timesave_per_element = data_cpu_unopt .- data_cpu_opt
data_cpu_no_elements_breakeven = opt_time ./ data_cpu_timesave_per_element

data_gpu_unopt = getfield.(data_gpu_unopt, :times)
data_gpu_unopt = median.(data_gpu_unopt) ./ N
data_gpu_opt = getfield.(data_gpu_opt, :times)
data_gpu_opt = median.(data_gpu_opt) ./ N       # benchmarked N elements at a time

data_gpu_timesave_per_element = (data_gpu_unopt .- data_gpu_opt)
data_gpu_no_elements_breakeven = opt_time ./ data_gpu_timesave_per_element

f = Figure(; size = (600, 500))
ax = Axis(
    f[1, 1];
    xlabel = "number of incoming photons",
    ylabel = "number of elements for break even",
    #limits = (nothing, _find_y_lims([data_gpu_no_elements_breakeven, data_cpu_no_elements_breakeven])),
    yminorgridvisible = true,
    yminorticksvisible = true,
    yminorticks = IntervalsBetween(10),
    xminorticksvisible = true,
    xminorticks = IntervalsBetween(5),
    #yscale = linear,
    xticks = ([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    #yticks = (yticks1, yticks2),
)

sc_cpu = plot!(ax, [(1:l)...], data_cpu_no_elements_breakeven; markersize = 12)
sc_gpu = plot!(ax, [(1:l)...], data_gpu_no_elements_breakeven; markersize = 12)

# Legend
labels = ["CPU", "GPU"]
elements = [sc_cpu, sc_gpu]

Legend(
    f[2, 1],
    elements,
    labels;
    tellheight = true,
    tellwidth = false,
    margin = (10, 10, 10, 10),
    #halign = :center,
    valign = :bottom,
    orientation = :horizontal,
)

save(joinpath(plotpath, "break_even.pdf"), f)
