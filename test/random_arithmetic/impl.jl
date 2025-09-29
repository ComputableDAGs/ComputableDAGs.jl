module RandomArith

using ComputableDAGs
using Random

# generates a number of random basic arithmetic tasks, based on the given seed and number of nodes
struct RandomArithmetic
    rng_seed::Int
    size::Int   # number of nodes to generate
end

# binary
struct PLUS <: AbstractComputeTask end
struct MINUS <: AbstractComputeTask end
struct MULT <: AbstractComputeTask end
struct DIV <: AbstractComputeTask end

# unary
struct NEGATE <: AbstractComputeTask end
struct SIN <: AbstractComputeTask end
struct COS <: AbstractComputeTask end
struct SQRT <: AbstractComputeTask end

# ternary
struct FMA <: AbstractComputeTask end

ComputableDAGs.children(::PLUS) = 2
ComputableDAGs.children(::MINUS) = 2
ComputableDAGs.children(::MULT) = 2
ComputableDAGs.children(::DIV) = 2

ComputableDAGs.children(::NEGATE) = 1
ComputableDAGs.children(::SIN) = 1
ComputableDAGs.children(::COS) = 1
ComputableDAGs.children(::SQRT) = 1

ComputableDAGs.children(::FMA) = 3

ComputableDAGs.compute_effort(::PLUS) = 1
ComputableDAGs.compute_effort(::MINUS) = 1
ComputableDAGs.compute_effort(::MULT) = 1
ComputableDAGs.compute_effort(::DIV) = 2

ComputableDAGs.compute_effort(::NEGATE) = 1
ComputableDAGs.compute_effort(::SIN) = 3
ComputableDAGs.compute_effort(::COS) = 3
ComputableDAGs.compute_effort(::SQRT) = 2

ComputableDAGs.compute_effort(::FMA) = 1

ComputableDAGs.compute(::PLUS, a, b) = a + b
ComputableDAGs.compute(::MINUS, a, b) = a - b
ComputableDAGs.compute(::MULT, a, b) = a * b
ComputableDAGs.compute(::DIV, a, b) = a / b

ComputableDAGs.compute(::NEGATE, a) = -a
ComputableDAGs.compute(::SIN, a) = sin(a)
ComputableDAGs.compute(::COS, a) = cos(a)
ComputableDAGs.compute(::SQRT, a) = sign(a) * sqrt(abs(a))  # prevent domain error

ComputableDAGs.compute(::FMA, a, b, c) = fma(a, b, c)

function _add_node(g::DAG, rng)
    input_nodes = ComputableDAGs.get_entry_nodes(g)

    n = rand(rng, 1:9)

    nodes = if (length(input_nodes) > 3)
        rand(rng, input_nodes, rand(1:3))
    else
        [rand(rng, input_nodes)]
    end

    if (1 <= n <= 4) # plus, minus, mult, div
        ct = if (n == 1)
            insert_node!(g, PLUS())
        elseif (n == 2)
            insert_node!(g, MINUS())
        elseif (n == 3)
            insert_node!(g, MULT())
        else
            insert_node!(g, DIV())
        end
        in1 = insert_node!(g, DataTask(sizeof(Float64)))
        in2 = insert_node!(g, DataTask(sizeof(Float64)))

        for node in nodes
            insert_edge!(g, ct, node)
        end
        insert_edge!(g, in1, ct)
        insert_edge!(g, in2, ct)
    elseif (5 <= n <= 8) # negate, sin, cos, sqrt
        ct = if (n == 5)
            insert_node!(g, NEGATE())
        elseif (n == 6)
            insert_node!(g, SIN())
        elseif (n == 7)
            insert_node!(g, COS())
        else
            insert_node!(g, SQRT())
        end
        in = insert_node!(g, DataTask(sizeof(Float64)))

        for node in nodes
            insert_edge!(g, ct, node)
        end
        insert_edge!(g, in, ct)
    elseif (n == 9) # fma
        ct = insert_node!(g, FMA())
        in1 = insert_node!(g, DataTask(sizeof(Float64)))
        in2 = insert_node!(g, DataTask(sizeof(Float64)))
        in3 = insert_node!(g, DataTask(sizeof(Float64)))

        for node in nodes
            insert_edge!(g, ct, node)
        end
        insert_edge!(g, in1, ct)
        insert_edge!(g, in2, ct)
        insert_edge!(g, in3, ct)
    end

    return nothing
end

function ComputableDAGs.graph(r::RandomArithmetic)
    rng = MersenneTwister(r.rng_seed)

    g = DAG()

    # this will be the result node
    insert_node!(g, DataTask(sizeof(Float64)))

    for _ in 1:r.size
        _add_node(g, rng)
    end

    input_nodes = ComputableDAGs.get_entry_nodes(g)

    c = 0
    for node in input_nodes
        c += 1
        node.name = "$c"
    end

    return g
end

function ComputableDAGs.input_expr(::RandomArithmetic, name::String, input_symbol::Symbol)
    return Meta.parse("$input_symbol[$(name)]")
end

function ComputableDAGs.input_type(::RandomArithmetic)
    return Vector{Float64}
end

end
