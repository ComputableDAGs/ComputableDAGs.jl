# == Function Generation Time ==
@load "data/bench.jld2"

data = result["f_gen"]
l = length(data)
data = getfield.(getindex.(Ref(data), SCATTERING_PROCESSES[1:l]), :times)
data = median.(data)

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel="number of outgoing B-ons",
    ylabel="function generation time",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
    yticks=(yticks1, yticks2),
)

scatter!(ax, [(1:l)...], data)

save(joinpath(plotpath, "f_gen_compton.pdf"), f)
