"""
   CDCost

Representation of a [`DAG`](@ref)'s cost as estimated by the [`GlobalMetricEstimator`](@ref).

# Fields:
`.data`: The total data transfer.\\
`.compute_effort`: The total compute effort.\\

# Functions:
`compute_intensity(::CDCost)`: The compute intensity, equals `.compute_effort / .data`.

!!! note
    Note that the `compute_intensity` doesn't necessarily make sense in the context of only operation costs.
    It will still work as intended when adding/subtracting to/from a `graph_cost` estimate.
"""
struct CDCost
    data::Float64
    compute_effort::Float64
end

compute_intensity(c::CDCost) = c.compute_effort / c.data

Base.:+(cost1::CDCost, cost2::CDCost) = CDCost(cost1.data + cost2.data, cost1.compute_effort + cost2.compute_effort)
Base.:-(cost1::CDCost, cost2::CDCost) = CDCost(cost1.data - cost2.data, cost1.compute_effort - cost2.compute_effort)

Base.zero(type::Type{T}) where {T <: CDCost} = T(0.0, 0.0)
Base.typemax(type::Type{T}) where {T <: CDCost} = T(Inf, Inf)

"""
    GlobalMetricEstimator <: AbstractEstimator

A simple estimator that adds up each node's set [`compute_effort`](@ref) and [`data`](@ref).
"""
struct GlobalMetricEstimator <: AbstractEstimator end

function cost_type(::GlobalMetricEstimator)
    return CDCost
end

function graph_cost(::GlobalMetricEstimator, dag::DAG)
    p = properties(dag)
    return CDCost(
        p.data,
        p.compute_effort
    )
end

function operation_effect(
        ::GlobalMetricEstimator, dag::DAG, operation::NodeReduction
    )
    input_node = dag.nodes[operation.input[1]]
    s = length(operation.input) - 1

    # sum of the data of all children will be multiplied by s
    temp_d = sum(data.(task.(children(dag, input_node))))

    return CDCost(
        s * -temp_d,
        s * -compute_effort(task(input_node)),
    )
end

function operation_effect(
        ::GlobalMetricEstimator, dag::DAG, operation::NodeSplit
    )
    input_node = dag.nodes[operation.input]

    s = length(input_node.parents) - 1

    # sum of the data of all children will be multiplied by s
    temp_d = sum(data.(task.(children(dag, input_node))))

    d = s * temp_d
    ce = s * compute_effort(task(input_node))
    return CDCost(d, ce)
end

function Base.print(io::IO, ::GlobalMetricEstimator)
    print(io, "global_metric")
    return nothing
end
