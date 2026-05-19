using ComputableDAGs

using ComputableDAGs: nodes

@testset "Create empty ComputableDAG" begin
    DAG = ComputableDAG()

    @test isempty(nodes(DAG))
end
