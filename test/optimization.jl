using ComputableDAGs
using Random

include("random_arithmetic/impl.jl")
using .RandomArith

RNG = Xoshiro(1)

@testset "Equal results after optimization" for optimizer in [
        ReductionOptimizer(), RandomWalkOptimizer(Xoshiro(2)),
    ]
    @testset "Random Arithmetic graph N=$N" for N in [10, 100, 1000]
        instance = RandomArithmetic(0, N)
        dag = graph(instance)

        compute_function = get_compute_function(dag, instance, cpu_st(), @__MODULE__)

        if (typeof(optimizer) <: RandomWalkOptimizer)
            optimize!(optimizer, dag, 100)
        elseif (typeof(optimizer) <: ReductionOptimizer)
            optimize_to_fixpoint!(optimizer, dag)
        end
        reduced_compute_function = get_compute_function(
            dag, instance, cpu_st(), @__MODULE__
        )

        input = [rand(RNG, Float64, 3 * N) for _ in 1:100]

        @test isapprox(compute_function.(input), reduced_compute_function.(input))
    end
end
