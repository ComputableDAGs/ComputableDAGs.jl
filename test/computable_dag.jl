using ComputableDAGs

using ComputableDAGs: nodes

@testset "Create empty ComputableDAG" begin
    cdag = ComputableDAG()

    @test isempty(nodes(cdag))
end

@testset "@assemble_dag macro" begin
    @compute_task Add (+)
    @compute_task Mul (*)

    cdag = @assemble_cdag begin end
    @test isempty(nodes(cdag))

    cdag2 = @assemble_cdag begin end
    @test isempty(nodes(cdag2))

    @test_throws "cannot use @assemble_cdag recursively" @assemble_cdag begin
        @assemble_cdag begin end
    end
end
