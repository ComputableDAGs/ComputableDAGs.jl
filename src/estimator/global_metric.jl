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

function cost_type(estimator::GlobalMetricEstimator)
    return CDCost
end

function graph_cost(estimator::GlobalMetricEstimator, graph::DAG)
    properties = get_properties(graph)
    return CDCost(
        properties.data,
        properties.compute_effort
    )
end

function operation_effect(
        estimator::GlobalMetricEstimator, graph::DAG, operation::NodeReduction
    )
    s = length(operation.input) - 1
    return CDCost(
        s * -data(task(operation.input[1])),
        s * -compute_effort(task(operation.input[1])),
    )
end

function operation_effect(
        estimator::GlobalMetricEstimator, graph::DAG, operation::NodeSplit
    )
    s = length(parents(operation.input)) - 1
    d = s * data(task(operation.input))
    ce = s * compute_effort(task(operation.input))
    return CDCost(d, ce)
end

function Base.print(io::IO, ::GlobalMetricEstimator)
    print(io, "global_metric")
    return nothing
end
