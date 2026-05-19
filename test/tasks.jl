using ComputableDAGs

using ComputableDAGs: AbstractTask, AbstractComputeTask, compute

@testset "Types" begin
    struct TestTaskA <: AbstractComputeTask end

    compute(::TestTaskA, x) = x

    @test TestTaskA <: AbstractTask
    @test TestTaskA <: AbstractComputeTask

    @test compute(TestTaskA(), 5) == 5
end

@testset "Macros" begin
    @compute_task Add (+)
    @test Add <: AbstractComputeTask
    @test compute(Add(), 1, 2) == 3

    @compute_task Mul (*)
    @test Mul <: AbstractComputeTask
    @test compute(Mul(), 1, 2) == 2

    @compute_task ComplexTask
    @test ComplexTask <: AbstractComputeTask
    @test_throws MethodError compute(ComplexTask(), 1, 2)

    @compute_task Parametrized{T1, T2}
    ComputableDAGs.compute(::Parametrized{<:Integer, <:Integer}, a, b) = a + b
    ComputableDAGs.compute(::Parametrized{<:AbstractFloat, <:AbstractFloat}, a, b) = a * b
    @test Parametrized{Int, Int} <: AbstractComputeTask
    @test Parametrized{Float64, Float64} <: AbstractComputeTask
    @test compute(Parametrized{Int, Int}(), 1, 2) == 3
    @test compute(Parametrized{Float64, Float64}(), 1.0, 2.0) == 2.0
end
