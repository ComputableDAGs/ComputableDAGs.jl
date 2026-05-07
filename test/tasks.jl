using ComputableDAGs

using ComputableDAGs: AbstractTask, AbstractComputeTask, compute

@testset "Types" begin
    struct TestTaskA <: AbstractComputeTask end

    compute(::TestTaskA, x) = x

    @test TestTaskA <: AbstractTask
    @test TestTaskA <: AbstractComputeTask

    @test compute(TestTaskA(), 5) == 5
end
