using ComputableDAGs

using ComputableDAGs: nodes

@testset "Create empty ComputableDAG" begin
    cdag = ComputableDAG()

    @test isempty(nodes(cdag))
end
