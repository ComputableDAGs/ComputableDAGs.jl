# == Function Execution Time CPU/GPU==
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

    data_gpu = getindex.(Ref(data_gpu), STEPS)
    data_gpu = getfield.(data_gpu, :times)
    data_gpu = median.(data_gpu)

    data_flops = getindex.(data_flops, Ref(2)) # graph properties
    data_flops = getfield.(data_flops, Ref(:compute_effort))

    f = Figure(; size=(600, 500))
    ax = Axis(
        f[1, 1];
        xlabel="number of optimization steps",
        ylabel="function execution time",
        limits=(nothing, _find_y_lims([data_cpu, data_gpu])),
        yminorgridvisible=true,
        yminorticksvisible=true,
        yminorticks=IntervalsBetween(10),
        xminorticksvisible=true,
        xminorticks=IntervalsBetween(5),
        yscale=log10,
        #xticks=(STEPS, string.(STEPS)),
        yticks=(yticks1, yticks2),
    )

    sc_cpu = plot!(ax, STEPS, data_cpu; markersize=12, color=colors[1])
    sc_gpu = plot!(ax, STEPS, data_gpu; markersize=12, color=colors[2])

    ax2 = Axis(
        f[1, 1];
        yaxisposition=:right,
        ylabel="FLOPs",
        limits=(nothing, _find_y_lims(data_flops)),
        yminorgridvisible=true,
        yminorticksvisible=true,
        yminorticks=IntervalsBetween(10),
        yscale=log10,
        yticks=yticks1,
    )
    hidespines!(ax2)
    hidexdecorations!(ax2)
    linkxaxes!(ax, ax2)

    sc_flops = plot!(ax2, STEPS, data_flops; markersize=12, color=colors[3])

    # Legend
    labels = ["CPU, 1 Element", "GPU, $N Elements", "FLOPs"]
    elements = [sc_cpu, sc_gpu, sc_flops]

    Legend(
        f[2, 1],
        elements,
        labels;
        tellheight=true,
        tellwidth=false,
        margin=(10, 10, 10, 10),
        halign=:left,
        valign=:bottom,
        orientation=:horizontal,
    )

    save(joinpath(plotpath, "opt_progress_flops", "opt_progress_$(proc_n(PROC)).pdf"), f)
end
