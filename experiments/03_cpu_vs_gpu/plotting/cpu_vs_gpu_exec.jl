# == Function Execution Time CPU/GPU==
@load "data/bench.jld2"     # N, result, graph_props

colors = Makie.wong_colors()

data = result
l = length(data)
data_cpu = getindex.(Ref(data), SCATTERING_PROCESSES[1:l])
data_cpu = getindex.(data_cpu, Ref("CPU"))
data_cpu = getfield.(data_cpu, :times)
data_cpu = median.(data_cpu)

data_gpu = getindex.(Ref(data), SCATTERING_PROCESSES[1:l])
data_gpu = getindex.(data_gpu, Ref("GPU"))
data_gpu = getfield.(data_gpu, :times)
data_gpu = median.(data_gpu)

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel="number of incoming photons",
    ylabel="function execution time",
    limits=(nothing, _find_y_lims([data_cpu, data_gpu])),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

sc_cpu = scatter!(ax, [(1:l)...], data_cpu; markersize=12)
sc_gpu = scatter!(ax, [(1:l)...], data_gpu; markersize=12)

# Legend
labels = [L"CPU, $%$N$ Elements", L"GPU, $%$N$ Elements"]
elements = [sc_cpu, sc_gpu]

Legend(f[1, 1], elements, labels; tellheight=false, tellwidth=false, margin=(10, 10, 10, 10), halign=:left, valign=:top)

save(joinpath(plotpath, "f_exec_cpu_vs_gpu.pdf"), f)
