# ratio of optimization for n samples for a given process
@load "data/bench_o3.jld2"     # N, result, graph_props

colors = Makie.wong_colors()

data = result

l = length(data)

xlimits = (1.0e0, 1.0e6)
xvalues = [logrange(xlimits[1], xlimits[2], 200)...]

xticks1 = [1, 10, 100, 1000, 10000, 100000, 1000000]
xticks2 = [L"$10^0$", L"$10^1$", L"$10^2$", L"$10^3$", L"$10^4$", L"$10^5$", L"$10^6$"]

f = Figure(; size = (600, 450))
ax = Axis(
    f[1, 1];
    xlabel = "number of samples",
    ylabel = "relative speedup through optimization",
    limits = (xlimits, nothing),
    yminorgridvisible = true,
    yminorticksvisible = true,
    #yminorticks = IntervalsBetween(),
    xminorticksvisible = false,
    #xminorticks = IntervalsBetween(5),
    #yscale = identity,
    xscale = log10,
    xticks = (xticks1, xticks2),
    #yticks = (yticks1, yticks2),
)

labels = []
elements = []

c = 0

for PROC in SCATTERING_PROCESSES[2:4]
    global c += 1
    data_proc = data[PROC]

    local data_cpu_unopt = data_proc["CPU"]["unoptimized"]
    local data_gpu_unopt = data_proc["GPU"]["unoptimized"]
    local data_cpu_opt = data_proc["CPU"]["optimized"]
    local data_gpu_opt = data_proc["GPU"]["optimized"]

    local opt_time = data[PROC]["OPTIM"]
    opt_time = opt_time.times
    opt_time = median(opt_time)

    data_cpu_unopt = data_cpu_unopt.times
    data_cpu_unopt = median(data_cpu_unopt)
    data_cpu_opt = data_cpu_opt.times
    data_cpu_opt = median(data_cpu_opt)

    data_gpu_unopt = data_gpu_unopt.times
    data_gpu_unopt = median(data_gpu_unopt) / N
    data_gpu_opt = data_gpu_opt.times
    data_gpu_opt = median(data_gpu_opt) / N       # benchmarked N elements at a time

    # function (closure) returning ratio for n elements
    f_cpu(n) = (n * data_cpu_unopt) / (n * data_cpu_opt + opt_time)
    f_gpu(n) = (n * data_gpu_unopt) / (n * data_gpu_opt + opt_time)

    # plot curves for these processes
    local line_cpu = lines!(ax, xvalues, f_cpu.(xvalues); linestyle = :solid, color = colors[c], linewidth = 2.5)
    local line_gpu = lines!(ax, xvalues, f_gpu.(xvalues); linestyle = :dash, color = colors[c], linewidth = 2.5)

    # Legend
    push!(labels, L"$e^\minus \gamma^{%$(proc_str(PROC))} \rightarrow e^{\minus} \gamma$")
    push!(elements, line_cpu)
end

line_breakeven = lines!(ax, xvalues, one.(xvalues); linestyle = :dot, color = "black", linewidth = 4)
push!(labels, "break-even point")
push!(elements, line_breakeven)

Legend(
    f[1, 1],
    elements,
    labels;
    tellheight = false,
    tellwidth = false,
    margin = (10, 10, 10, 10),
    halign = :left,
    valign = :top,
    orientation = :vertical,
    #nbanks = 1
)

save(joinpath(plotpath, "optim_total_speedup.pdf"), f)
