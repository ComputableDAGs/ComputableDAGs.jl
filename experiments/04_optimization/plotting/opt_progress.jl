# == Function Execution Time CPU/GPU==
@load "data/bench.jld2"     # N, result, graph_props

colors = Makie.wong_colors()

data = result

for PROC in SCATTERING_PROCESSES
    local proc_data = data[PROC]
    local data_cpu = proc_data["CPU"]
    local data_gpu = proc_data["GPU"]

    local l = length(data_cpu)
    STEPS = [10 * i for i in 0:(l - 1)]

    data_cpu = getindex.(Ref(data_cpu), STEPS)
    data_cpu = getfield.(data_cpu, :times)
    data_cpu = median.(data_cpu)

    data_gpu = getindex.(Ref(data_gpu), STEPS)
    data_gpu = getfield.(data_gpu, :times)
    data_gpu = median.(data_gpu)

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

    sc_cpu = plot!(ax, STEPS, data_cpu; markersize=12)
    sc_gpu = plot!(ax, STEPS, data_gpu; markersize=12)

    # Legend
    labels = ["CPU, 1 Element", "GPU, $N Elements"]
    elements = [sc_cpu, sc_gpu]

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

    save(joinpath(plotpath, "opt_progress", "opt_progress_$(proc_n(PROC)).pdf"), f)
end
