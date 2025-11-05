using ComputableDAGs
using StaticArrays

using ComputableDAGs: is_valid, input_expr, input_type

include("strassen/impl.jl")
using .MatrixMultiplicationImpl

TEST_TYPES = (Int32, Int64, Float32, Float64)
TEST_SIZES = (16, 32, 64, 128) #, 256
NODE_NUMBERS = (4, 70, 532, 3766) #, 26404
EDGE_NUMBERS = (3, 96, 747, 5304) #, 37203

@testset "Strassen Matrix Type $M_T Size $(TEST_SIZES[M_SIZE_I])" for (M_T, M_SIZE_I) in
    Iterators.product(
        TEST_TYPES, eachindex(TEST_SIZES)
    )
    M_SIZE = TEST_SIZES[M_SIZE_I]
    NODE_NUM_EXPECTED = NODE_NUMBERS[M_SIZE_I]
    EDGE_NUM_EXPECTED = EDGE_NUMBERS[M_SIZE_I]

    input = (rand(M_T, (M_SIZE, M_SIZE)), rand(M_T, (M_SIZE, M_SIZE)))

    mm = MatrixMultiplication{M_T}(M_SIZE)

    @testset "Construction" begin
        @test mm.size == M_SIZE
        @test input_type(mm) == Tuple{Matrix{M_T}, Matrix{M_T}}
        @test input isa input_type(mm)
        @test_throws "unknown data node name C" input_expr(mm, "C", :input)
    end

    g = graph(mm)
    @testset "DAG properties" begin
        @test is_valid(g)

        @test length(ComputableDAGs.entry_nodes(g)) == 2
        @test exit_node(g) isa DataTaskNode

        props = properties(g)
        @test NODE_NUM_EXPECTED == props.number_of_nodes
        @test EDGE_NUM_EXPECTED == props.number_of_edges
    end

    f = compute_function(g, mm, cpu_st(), @__MODULE__)

    if (M_SIZE > 256)
        continue
    end

    @testset "Execution" begin
        @test Base.return_types(f, (typeof(input),))[1] == typeof(input[1])
        @test isapprox(f(input), input[1] * input[2])
    end

    #=@testset "Execution with closures" begin
        f_closures = compute_function(g, mm, cpu_st(), @__MODULE__; closures_size = 100)

        @test Base.return_types(f_closures, (typeof(input),))[1] == typeof(input[1])
        @test isapprox(f_closures(input), input[1] * input[2])
    end=#

    @testset "Function generation with concrete input type" begin
        f_concrete = compute_function(
            g, mm, cpu_st(), @__MODULE__; concrete_input_type = typeof(input)
        )

        @test Base.return_types(f_concrete, (typeof(input),))[1] == typeof(input[1])
        @test isapprox(f_concrete(input), input[1] * input[2])
    end

    @testset "Execution with reduction optimization" begin
        optimize_to_fixpoint!(ReductionOptimizer(), g)
        f_optimized = compute_function(g, mm, cpu_st(), @__MODULE__)

        @test isapprox(f_optimized(input), input[1] * input[2])
    end
end
