# == Function Speedup CPU/GPU==

using Unitful: percent

colors = Makie.wong_colors()

@load "data/bench_o0.jld2"     # N, result, graph_props
data_o0 = result

@load "data/bench_o3.jld2"
data_o3 = result

for PROC in SCATTERING_PROCESSES
    local proc_data_o0 = data_o0[PROC]
    local data_cpu_o0 = proc_data_o0["CPU"]
    local data_gpu_o0 = proc_data_o0["GPU"]

    local proc_data_o3 = data_o3[PROC]
    local data_cpu_o3 = proc_data_o3["CPU"]
    local data_gpu_o3 = proc_data_o3["GPU"]

    local data_flops = graph_props[PROC]

    local l = length(data_cpu_o0)
    STEPS = [10 * i for i in 0:(l - 1)]

    data_cpu_o0 = getindex.(Ref(data_cpu_o0), STEPS)
    data_cpu_o0 = getfield.(data_cpu_o0, :times)
    data_cpu_o0 = median.(data_cpu_o0)
    data_cpu_o0 = data_cpu_o0[1] ./ data_cpu_o0

    data_gpu_o0 = getindex.(Ref(data_gpu_o0), STEPS)
    data_gpu_o0 = getfield.(data_gpu_o0, :times)
    data_gpu_o0 = median.(data_gpu_o0)
    data_gpu_o0 = data_gpu_o0 ./ Ref(N)
    data_gpu_o0 = data_gpu_o0[1] ./ data_gpu_o0

    data_cpu_o3 = getindex.(Ref(data_cpu_o3), STEPS)
    data_cpu_o3 = getfield.(data_cpu_o3, :times)
    data_cpu_o3 = median.(data_cpu_o3)
    data_cpu_o3 = data_cpu_o3[1] ./ data_cpu_o3

    data_gpu_o3 = getindex.(Ref(data_gpu_o3), STEPS)
    data_gpu_o3 = getfield.(data_gpu_o3, :times)
    data_gpu_o3 = median.(data_gpu_o3)
    data_gpu_o3 = data_gpu_o3 ./ Ref(N)
    data_gpu_o3 = data_gpu_o3[1] ./ data_gpu_o3

    data_flops = getindex.(data_flops, Ref(2)) # graph properties
    data_flops = getfield.(data_flops, Ref(:compute_effort))
    data_flops = data_flops[1] ./ data_flops

    f = Figure(; size = (600, 500))
    ax = Axis(
        f[1, 1];
        xlabel = "number of optimization steps",
        ylabel = "relative speedup",
        limits = (nothing, (0.5, 7.5)),
        yminorgridvisible = true,
        yminorticksvisible = true,
        yminorticks = IntervalsBetween(5),
        xminorticksvisible = true,
        xminorticks = IntervalsBetween(5),
        #yscale=log10,
        #xticks=(STEPS, string.(STEPS)),
        yticks = ([1, 3, 5, 7], ["1", "3", "5", "7"]),
    )

    sc_cpu_o0 = plot!(ax, STEPS, data_cpu_o0; markersize = 12, color = colors[1])
    sc_gpu_o0 = plot!(ax, STEPS, data_gpu_o0; markersize = 12, color = colors[2])
    sc_cpu_o3 = plot!(ax, STEPS, data_cpu_o3; markersize = 12, marker = :star5, color = colors[3])
    sc_gpu_o3 = plot!(ax, STEPS, data_gpu_o3; markersize = 12, marker = :star5, color = colors[4])
    sc_flops = plot!(ax, STEPS, data_flops; marker = :xcross, markersize = 15, color = :black)

    # Legend
    labels = ["CPU (-O0)", "GPU (-O0)", "CPU (-O3)", "GPU (-O3)", "theoretical"]
    elements = [sc_cpu_o0, sc_gpu_o0, sc_cpu_o3, sc_gpu_o3, sc_flops]

    Legend(
        f[2, 1], elements, labels; tellheight = true, tellwidth = false, margin = (10, 10, 10, 10), orientation = :horizontal
    )

    save(joinpath(plotpath, "opt_progress_speedup", "opt_progress_$(proc_n(PROC)).pdf"), f)
end
