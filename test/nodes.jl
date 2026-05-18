using ComputableDAGs
using UUIDs

using ComputableDAGs:
    AbstractComputeTask,
    Node,
    is_entry_node,
    is_exit_node,
    task,
    isnull,
    NULL_UUID

@testset "Nodes" begin
    struct TestTaskA <: AbstractComputeTask end
    struct TestTaskB <: AbstractComputeTask end

    @testset "Newly created node is empty" begin
        n = Node(TestTaskA())

        @test task(n) == TestTaskA()
        @test !isnull(n.id)
        @test isempty(n.dependencies)
        @test isempty(n.dependents)

        @test isnull(n.antecedent)
        @test isnull(n.precedent)

        @test iszero(n.t_level)
        @test iszero(n.b_level)
    end

    @testset "is_exit_node and is_entry_node on empty node" begin
        n = Node(TestTaskA())

        @test is_entry_node(n)
        @test is_exit_node(n)
    end
end
