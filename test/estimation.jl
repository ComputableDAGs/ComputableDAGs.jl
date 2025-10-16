using ComputableDAGs

include("strassen/impl.jl")
using .MatrixMultiplicationImpl

@testset "GlobalMetricsEstimator" begin
    @testset "CD cost" begin
        using ComputableDAGs: CDCost
        c1 = CDCost(10, 10)
        c2 = CDCost(5, 15)

        @test compute_intensity(c1) == 1.0
        @test compute_intensity(c2) == 3.0
        @test typeof(c1) == CDCost

        @test c1 != c2
        @test c1 == c1
        @test c2 == c2

        @test c1 + c2 == CDCost(15, 25)
        @test c1 - c2 == CDCost(5, -5)

        @test zero(CDCost) == CDCost(0.0, 0.0)
        @test typemax(CDCost) == CDCost(Inf, Inf)
    end

    @testset "Estimating" begin
        using ComputableDAGs: DataTask, DataTaskNode, cost_type, graph_cost

        estimator = GlobalMetricEstimator()

        @test cost_type(estimator) == CDCost

        buf = IOBuffer()
        print(buf, estimator)
        @test String(take!(buf)) == "global_metric"

        M_SIZE = 32
        mm = MatrixMultiplication{Float64}(M_SIZE)
        g = graph(mm)

        c = graph_cost(estimator, g)
        @test c == CDCost(176128.0, 4496.0)
        @test isapprox(compute_intensity(c), 0.02552688953488372)

        ops = operations(g)
        @test length(ops).node_reductions == 0
        @test length(ops).node_splits == 15

        # TODO: add real operation effect tests
    end
end
