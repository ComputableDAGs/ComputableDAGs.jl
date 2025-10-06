using ComputableDAGs
using RuntimeGeneratedFunctions
using Random
using QEDFeynmanDiagrams
using QEDprocesses
using QEDcore
using QEDbase
RuntimeGeneratedFunctions.init(@__MODULE__)

RNG = Xoshiro(1)
MODEL = PerturbativeQED()
PROC = ScatteringProcess(
    (Electron(), Photon()),
    (Electron(), Photon(), Photon(), Photon(), Photon())
)
INPSL = FlatPhaseSpaceLayout(TwoBodyRestSystem())
PSP = PhaseSpacePoint(PROC, MODEL, INPSL, tuple(rand(SFourMomentum, number_incoming_particles(PROC))...), tuple(rand(SFourMomentum, number_outgoing_particles(PROC))...))

@info "Building the graph"
@time g = graph(PROC)

@show g

@info "Building the function"
@time f = get_compute_function(g, PROC, cpu_st(), @__MODULE__; closures_size = 100, concrete_input_type = typeof(PSP));

#=@info "Writing llvm code"
@time open("llvm.out", write = true) do file
    code_llvm(file, f, (typeof(PSP),))
end=#

@info "Calling function once"
@time f(PSP)

@info "Benchmarking function"
using BenchmarkTools
@benchmark f($PSP)
