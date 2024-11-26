# == Function Execution Time CPU/GPU==

using Unitful: percent

@load "data/bench.jld2"     # N, result, graph_props

colors = Makie.wong_colors()

data = result

for PROC in SCATTERING_PROCESSES
    local proc_data = data[PROC]
    local data_cpu = proc_data["CPU"]
    local data_gpu = proc_data["GPU"]
    local data_flops = graph_props[PROC]

    local l = length(data_cpu)
    STEPS = [10 * i for i in 0:(l - 1)]

    data_cpu = getindex.(Ref(data_cpu), STEPS)
    data_cpu = getfield.(data_cpu, :times)
    data_cpu = median.(data_cpu)
    data_cpu = data_cpu ./ data_cpu[1]

    data_gpu = getindex.(Ref(data_gpu), STEPS)
    data_gpu = getfield.(data_gpu, :times)
    data_gpu = median.(data_gpu)
    data_gpu = data_gpu ./ Ref(N)
    data_gpu = data_gpu ./ data_gpu[1]

    data_flops = getindex.(data_flops, Ref(2)) # graph properties
    data_flops = getfield.(data_flops, Ref(:compute_effort))
    data_flops = data_flops ./ data_flops[1]

    f = Figure(; size = (600, 500))
    ax = Axis(
        f[1, 1];
        xlabel = "number of optimization steps",
        ylabel = "normalized execution time",
        limits = (nothing, (-0.05, 1.05)),
        yminorgridvisible = true,
        yminorticksvisible = true,
        yminorticks = IntervalsBetween(5),
        xminorticksvisible = true,
        xminorticks = IntervalsBetween(5),
        #yscale=log10,
        #xticks=(STEPS, string.(STEPS)),
        yticks = ([0.0, 0.5, 1.0], ["0 %", "50 %", "100 %"]),
    )

    sc_cpu = plot!(ax, STEPS, data_cpu; markersize = 12, color = colors[1])
    sc_gpu = plot!(ax, STEPS, data_gpu; markersize = 12, color = colors[2])
    sc_flops = plot!(ax, STEPS, data_flops; marker = :xcross, markersize = 10, color = :black)

    # Legend
    labels = ["CPU", "GPU", "FLOPs (theoretical)"]
    elements = [sc_cpu, sc_gpu, sc_flops]

    Legend(
        f[2, 1], elements, labels; tellheight = true, tellwidth = false, margin = (10, 10, 10, 10), orientation = :horizontal
    )

    save(joinpath(plotpath, "opt_progress_flops_norm", "opt_progress_$(proc_n(PROC)).pdf"), f)
end
