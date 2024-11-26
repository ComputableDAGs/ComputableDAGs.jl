# == Function Compile Time ==
@load "data/bench.jld2"

l = length(comp_times)
data = getindex.(Ref(comp_times), SCATTERING_PROCESSES[1:l])
for i in eachindex(data)
    data[i] = data[i] *= 1e9 # convert to nanoseconds
end
data = median.(data)

f = Figure()
ax = Axis(
    f[1, 1];
    xlabel="number of outgoing B-ons",
    ylabel="function compile time",
    limits=(nothing, _find_y_lims(data)),
    yminorgridvisible=true,
    yminorticksvisible=true,
    yminorticks=IntervalsBetween(10),
    yscale=log10,
    yticks=(yticks1, yticks2),
    xticks=([(1:l)...], proc_str.(SCATTERING_PROCESSES[1:l])),
)

scatter!(ax, [(1:l)...], data)

save(joinpath(plotpath, "f_compile_compton.pdf"), f)
