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

BenchmarkTools.DEFAULT_PARAMETERS.seconds = 5.0

RuntimeGeneratedFunctions.init(@__MODULE__)

# ------------------

MODEL = PerturbativeQED()

SCATTERING_PROCESSES = [
    #"ke->ke",               # 1
    #"kke->ke",              # 2
    "kkke->ke",             # 3
    "kkkke->ke",            # 4
    #"kkkkke->ke",           # 5
]

STEP_SIZE = 10

SUITE = BenchmarkGroup()

graph_props = Dict{String, Vector{Tuple{Int, GraphProperties}}}()

@info "== Reductions benchmark =="

N = 16384
for INSTANCE_STR in SCATTERING_PROCESSES
    INSTANCE = parse_process(INSTANCE_STR, QEDModel())
    @info "$INSTANCE_STR"
    flush(stdout)

    INSTANCE_SUITE = BenchmarkGroup()
    INSTANCE_SUITE["CPU"] = BenchmarkGroup()
    INSTANCE_SUITE["GPU"] = BenchmarkGroup()
    INSTANCE_SUITE["OPTIM"] = BenchmarkGroup()

    # prepare inputs
    input = PhaseSpacePoint(
        INSTANCE,
        MODEL,
        FlatPhaseSpaceLayout(ComptonRestSystem()),
        tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles(INSTANCE))...),
        tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles(INSTANCE))...),
    )
    cu_inputs = CuVector(
        [
            PhaseSpacePoint(
                    INSTANCE,
                    MODEL,
                    FlatPhaseSpaceLayout(ComptonRestSystem()),
                    tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles(INSTANCE))...),
                    tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles(INSTANCE))...),
                ) for _ in 1:N
        ]
    )
    cu_outputs = CuVector([0.0 for _ in 1:N])

    # build graph
    g = graph(INSTANCE)
    graph_props[INSTANCE_STR] = Tuple{Int, GraphProperties}[]
    steps = 0

    # benchmark at different points of optimization
    push!(graph_props[INSTANCE_STR], (steps, get_properties(g)))
    func = get_compute_function(g, INSTANCE, cpu_st(), @__MODULE__; closures_size = 0)
    func(input)
    cu_func = eval(kernel(CUDAGPU, g, INSTANCE, @__MODULE__))
    INSTANCE_SUITE["CPU"][steps] = @benchmark $func($input)
    INSTANCE_SUITE["GPU"][steps] = @benchmark (
        CUDA.@sync (
            @cuda threads = t blocks = b k( #=always_inline = true=#
                in,
                out,
                n,
            )
        )
    ) setup = (n = $N; t = 32; b = $N ÷ 32; k = $cu_func; in = $cu_inputs; out = $cu_outputs)
    INSTANCE_SUITE["OPTIM"][steps] = @benchmark optimize!(ReductionOptimizer(), g_temp, STEP_SIZE) setup = (
        g_temp = graph($INSTANCE)
    )

    while !fixpoint_reached(ReductionOptimizer(), g)
        @info "    Steps: $steps"
        steps += STEP_SIZE
        optimize!(ReductionOptimizer(), g, STEP_SIZE)
        push!(graph_props[INSTANCE_STR], (steps, get_properties(g)))
        func = get_compute_function(g, INSTANCE, cpu_st(), @__MODULE__; closures_size = 0)
        func(input)

        cu_func = eval(kernel(CUDAGPU, g, INSTANCE, @__MODULE__))

        INSTANCE_SUITE["OPTIM"][steps] = @benchmark optimize!(ReductionOptimizer(), g_temp, STEP_SIZE) setup = (
            g_temp = graph($INSTANCE); optimize!(ReductionOptimizer(), g_temp, $steps) # generate and reduce up to that point
        )
        INSTANCE_SUITE["CPU"][steps] = @benchmark $func($input)
        INSTANCE_SUITE["GPU"][steps] = @benchmark (
            CUDA.@sync (
                @cuda threads = t blocks = b k( #=always_inline = true=#
                    in,
                    out,
                    n,
                )
            )
        ) setup = (n = $N; t = 32; b = $N ÷ 32; k = $cu_func; in = $cu_inputs; out = $cu_outputs)
    end

    @info "    Steps: $steps"
    flush(stdout)

    SUITE[INSTANCE_STR] = INSTANCE_SUITE

    result = SUITE
    @save "data/bench_o0.jld2" result graph_props N
end

result = SUITE

@save "data/bench_o0.jld2" result graph_props N
