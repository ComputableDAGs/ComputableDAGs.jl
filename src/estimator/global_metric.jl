"""
   CDCost

Representation of a [`DAG`](@ref)'s cost as estimated by the [`GlobalMetricEstimator`](@ref).

# Fields:
`.data`: The total data transfer.\\
`.compute_effort`: The total compute effort.\\
`.compute_intensity`: The compute intensity, will always equal `.compute_effort / .data`.


!!! note
    Note that the `compute_intensity` doesn't necessarily make sense in the context of only operation costs.
    It will still work as intended when adding/subtracting to/from a `graph_cost` estimate.
"""
const CDCost = NamedTuple{
    (:data, :compute_effort, :compute_intensity), Tuple{Float64, Float64, Float64},
}

function Base.:+(cost1::CDCost, cost2::CDCost)::CDCost
    d = cost1.data + cost2.data
    ce = compute_effort = cost1.compute_effort + cost2.compute_effort
    return (data = d, compute_effort = ce, compute_intensity = ce / d)::CDCost
end

function Base.:-(cost1::CDCost, cost2::CDCost)::CDCost
    d = cost1.data - cost2.data
    ce = compute_effort = cost1.compute_effort - cost2.compute_effort
    return (data = d, compute_effort = ce, compute_intensity = ce / d)::CDCost
end

function Base.isless(cost1::CDCost, cost2::CDCost)::Bool
    return cost1.data + cost1.compute_effort < cost2.data + cost2.compute_effort
end

function Base.zero(type::Type{CDCost})
    return (data = 0.0, compute_effort = 0.0, compute_intensity = 0.0)::CDCost
end

function Base.typemax(type::Type{CDCost})
    return (data = Inf, compute_effort = Inf, compute_intensity = 0.0)::CDCost
end

"""
    GlobalMetricEstimator <: AbstractEstimator

A simple estimator that adds up each node's set [`compute_effort`](@ref) and [`data`](@ref).
"""
struct GlobalMetricEstimator <: AbstractEstimator end

function cost_type(estimator::GlobalMetricEstimator)::Type{CDCost}
    return CDCost
end

function graph_cost(estimator::GlobalMetricEstimator, graph::DAG)
    properties = get_properties(graph)
    return (
        data = properties.data,
        compute_effort = properties.compute_effort,
        compute_intensity = properties.compute_intensity,
    )::CDCost
end

function operation_effect(
        estimator::GlobalMetricEstimator, graph::DAG, operation::NodeReduction
    )
    s = length(operation.input) - 1
    return (
        data = s * -data(task(operation.input[1])),
        compute_effort = s * -compute_effort(task(operation.input[1])),
        compute_intensity = typeof(operation.input) <: DataTaskNode ? 0.0 : Inf,
    )::CDCost
end

function operation_effect(
        estimator::GlobalMetricEstimator, graph::DAG, operation::NodeSplit
    )
    s::Float64 = length(parents(operation.input)) - 1
    d::Float64 = s * data(task(operation.input))
    ce::Float64 = s * compute_effort(task(operation.input))
    return (data = d, compute_effort = ce, compute_intensity = ce / d)::CDCost
end

function Base.print(io::IO, ::GlobalMetricEstimator)
    print(io, "global_metric")
    return nothing
end
