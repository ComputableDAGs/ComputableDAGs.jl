# == Function Execution Time ==
@load "data/bench.jld2"

colors = Makie.wong_colors()

data = result["f_exec"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = median.(data)

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel="number of outgoing B-ons",
    ylabel="function execution time",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

scatter!(ax, [(1:l)...], data; markersize=12)

save(joinpath(plotpath, "f_exec_compton.pdf"), f)
