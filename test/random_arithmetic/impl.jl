module RandomArith

using ComputableDAGs
using Random
using StatsBase

using ComputableDAGs: DataTask

export RandomArithmetic

# generates a number of random basic arithmetic tasks, based on the given seed and number of nodes
struct RandomArithmetic
    rng_seed::Int
    size::Int   # number of nodes to generate
end

const EPS = 1.0e-6

# binary
@compute_task PLUS 1 (+)
@compute_task MINUS 1 (-)
@compute_task MULT 1 (*)
@compute_task DIV 2 (a, b) -> abs(b) < EPS ? a / EPS : a / b

# unary
@compute_task NEGATE 1 (-)
@compute_task SIN 3 a -> isfinite(a) ? sin(a) : zero(Float64) # prevent domain errors
@compute_task COS 3 a -> isfinite(a) ? cos(a) : one(Float64)
@compute_task SQRT 2 a -> sign(a) * sqrt(abs(a))  # prevent domain error

# ternary
@compute_task FMA 1 fma

function _add_node(g::DAG, rng, c)
    input_nodes = ComputableDAGs.get_entry_nodes(g)

    n = rand(rng, 1:9)

    nodes = if (length(input_nodes) > 3)
        sample(rng, input_nodes, rand(1:3); replace = false)
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
        in1 = insert_node!(g, DataTask(sizeof(Float64)), "$(c += 1)")
        in2 = insert_node!(g, DataTask(sizeof(Float64)), "$(c += 1)")

        for node in nodes
            insert_edge!(g, ct, node)
        end
        insert_edge!(g, in1, ct, 1)
        insert_edge!(g, in2, ct, 2)
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
        in = insert_node!(g, DataTask(sizeof(Float64)), "$(c += 1)")

        for node in nodes
            insert_edge!(g, ct, node)
        end
        insert_edge!(g, in, ct)
    elseif (n == 9) # fma
        ct = insert_node!(g, FMA())
        in1 = insert_node!(g, DataTask(sizeof(Float64)), "$(c += 1)")
        in2 = insert_node!(g, DataTask(sizeof(Float64)), "$(c += 1)")
        in3 = insert_node!(g, DataTask(sizeof(Float64)), "$(c += 1)")

        for node in nodes
            insert_edge!(g, ct, node)
        end
        insert_edge!(g, in1, ct, 1)
        insert_edge!(g, in2, ct, 2)
        insert_edge!(g, in3, ct, 3)
    end

    return nothing
end

function ComputableDAGs.graph(r::RandomArithmetic)
    rng = Xoshiro(r.rng_seed)

    g = DAG()

    # this will be the result node
    insert_node!(g, DataTask(sizeof(Float64)))

    c = 0
    for _ in 1:r.size
        _add_node(g, rng, c += 1)
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
