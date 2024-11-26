using ComputableDAGs
using Pkg
Pkg.develop(; path = "/home/reinha57/repos/QEDFeynman.jl/")
using QEDFeynman
using RuntimeGeneratedFunctions
using BenchmarkTools
using QEDcore, QEDprocesses
using Logging
using JLD2
using CUDA

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 120.0

RuntimeGeneratedFunctions.init(@__MODULE__)

# ------------------

MODEL = PerturbativeQED()

SCATTERING_PROCESSES = [
    "ke->ke",               # 1
    "kke->ke",              # 2
    "kkke->ke",             # 3
    "kkkke->ke",            # 4
    "kkkkke->ke",           # 5
    "kkkkkke->ke",          # 6
    #"kkkkkkke->ke",         # 7 -> StackOverflow
]

SUITE = BenchmarkGroup()

graph_props = Dict{String, GraphProperties}()

@info "== CPU vs GPU benchmark =="

N = 16384
for INSTANCE_STR in SCATTERING_PROCESSES
    INSTANCE = parse_process(INSTANCE_STR, QEDModel())
    @info "$INSTANCE_STR"

    INSTANCE_SUITE = BenchmarkGroup()

    # build & optimize graph
    g = graph(INSTANCE)
    optimize_to_fixpoint!(ReductionOptimizer(), g)
    graph_props[INSTANCE_STR] = get_properties(g)

    # build function & inputs
    func = get_compute_function(g, INSTANCE, cpu_st(), @__MODULE__; closures_size = 0)
    inputs = [
        PhaseSpacePoint(
                INSTANCE,
                MODEL,
                FlatPhaseSpaceLayout(ComptonRestSystem()),
                tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles(INSTANCE))...),
                tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles(INSTANCE))...),
            ) for i in 1:N
    ]

    cu_func = eval(kernel(CUDAGPU, g, INSTANCE, @__MODULE__))
    cu_inputs = CuVector(inputs)
    cu_outputs = CuVector([0.0 for _ in 1:N])

    # create benchmarks
    INSTANCE_SUITE["CPU"] = @benchmarkable f.(i) setup = (f = $func; i = $inputs; GC.gc())
    INSTANCE_SUITE["GPU"] = @benchmarkable (
        CUDA.@sync (
            @cuda threads = t blocks = b always_inline = true k(
                in, out, n
            )
        )
    ) setup = (n = $N; t = 32; b = $N ÷ 32; k = $cu_func; in = $cu_inputs; out = $cu_outputs)

    SUITE[INSTANCE_STR] = INSTANCE_SUITE
end

tune!(SUITE; verbose = true)
result = run(SUITE; verbose = true)

@save "data/bench.jld2" result graph_props N
