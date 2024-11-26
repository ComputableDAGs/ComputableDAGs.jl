using Distributed
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

global_logger(NullLogger())

function time_compilation(expr; setup = nothing)
    ps = addprocs(1)
    remotecall_fetch(only(ps)) do
        @eval begin
            using QEDprocesses, QEDcore, ComputableDAGs, QEDFeynman, CUDA
        end
    end

    (; compile_time) = remotecall_fetch(only(ps)) do
        @eval begin
            $setup
            @timed $expr
        end
    end
    rmprocs(ps)
    return compile_time
end

function bench_compilation(expr; setup = nothing, n = 2)
    times = Float64[]
    for _ in 1:n
        push!(times, time_compilation(expr; setup = setup))
    end

    return times
end

# ------------------

MODEL = PerturbativeQED()

SCATTERING_PROCESSES = [
    "ke->ke",               # 1
    "kke->ke",              # 2
    "kkke->ke",             # 3
    "kkkke->ke",            # 4
    "kkkkke->ke",           # 5
    #"kkkkkke->ke",          # 6
    #"kkkkkkke->ke",         # 7
    #"kkkkkkkke->ke",        # 8
    #"kkkkkkkkke->ke",       # 9
]

SUITE = BenchmarkGroup()
SUITE["graph_gen"] = BenchmarkGroup()

graph_props = Dict{String, GraphProperties}()
comp_times = Dict{String, Vector{Float64}}()
comp_times_gpu = Dict{String, Vector{Float64}}()
node_dicts = Dict{String, Dict{Type, Int64}}()

for INSTANCE_STR in SCATTERING_PROCESSES
    INSTANCE = parse_process(INSTANCE_STR, QEDModel())
    println("$INSTANCE_STR")
    graph(INSTANCE)
    SUITE["graph_gen"][INSTANCE_STR] = @benchmarkable graph(proc) setup = (proc = $INSTANCE; GC.gc())

    g = graph(INSTANCE)
    graph_props[INSTANCE_STR] = get_properties(g)

    node_dicts[INSTANCE_STR] = Dict{Type, Int64}()
    for node in g.nodes
        if haskey(node_dicts[INSTANCE_STR], typeof(task(node)))
            node_dicts[INSTANCE_STR][typeof(task(node))] = node_dicts[INSTANCE_STR][typeof(task(node))] + 1
        else
            node_dicts[INSTANCE_STR][typeof(task(node))] = 1
        end
    end

    psp = PhaseSpacePoint(
        INSTANCE,
        MODEL,
        FlatPhaseSpaceLayout(ComptonRestSystem()),
        tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles(INSTANCE))...),
        tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles(INSTANCE))...),
    )

    func = get_compute_function(g, INSTANCE, cpu_st(), @__MODULE__; closures_size = 0, concrete_input_type = typeof(psp))

    SUITE["f_gen"][INSTANCE_STR] = @benchmarkable get_compute_function(g_, proc, machine, @__MODULE__; closures_size = 0) setup = (
        g_ = $g; proc = $INSTANCE; machine = cpu_st(); GC.gc()
    )

    if graph_props[INSTANCE_STR].number_of_nodes > 30000
        continue
    end

    comp_times[INSTANCE_STR] = bench_compilation(
        :(f(p));
        setup = quote
            using QEDcore, QEDprocesses, QEDFeynman, RuntimeGeneratedFunctions
            RuntimeGeneratedFunctions.init(@__MODULE__)
            p = PhaseSpacePoint(
                $INSTANCE,
                $MODEL,
                FlatPhaseSpaceLayout(ComptonRestSystem()),
                tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles($INSTANCE))...),
                tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles($INSTANCE))...),
            )
            f = get_compute_function($g, $INSTANCE, cpu_st(), @__MODULE__; closures_size = 0, concrete_input_type = typeof(p))
        end,
    )
    println("collected $(length(comp_times[INSTANCE_STR])) compile time samples")

    comp_times_gpu[INSTANCE_STR] = bench_compilation(
        :(@cuda launch = false cu_func(cu_inputs, cu_outputs, N));
        setup = quote
            using QEDcore, QEDprocesses, QEDFeynman, RuntimeGeneratedFunctions, CUDA
            RuntimeGeneratedFunctions.init(@__MODULE__)

            N = 16

            psps = [
                PhaseSpacePoint(
                        $INSTANCE,
                        $MODEL,
                        FlatPhaseSpaceLayout(ComptonRestSystem()),
                        tuple((rand(SFourMomentum) for _ in 1:number_incoming_particles($INSTANCE))...),
                        tuple((rand(SFourMomentum) for _ in 1:number_outgoing_particles($INSTANCE))...),
                    ) for i in 1:N
            ]

            cu_func = eval(kernel(CUDAGPU, $g, $INSTANCE, @__MODULE__))
            cu_inputs = CuVector(psps)
            cu_outputs = CuVector([0.0 for _ in 1:N])
        end
    )
    println("collected $(length(comp_times_gpu[INSTANCE_STR])) compile time samples of GPU")

    SUITE["f_exec"][INSTANCE_STR] = @benchmarkable f(input) setup = (f = $func; input = $psp; GC.gc())
end

tune!(SUITE)
result = run(SUITE; verbose = true)

BenchmarkTools.save("data/bench.json", result)
@save "data/bench.jld2" result graph_props node_dicts comp_times comp_times_gpu
