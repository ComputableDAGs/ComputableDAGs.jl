"""
   CDCost

Representation of a [`DAG`](@ref)'s cost as estimated by the [`GlobalMetricEstimator`](@ref).

# Fields:
`.data`: The total data transfer.\\
`.computeEffort`: The total compute effort.\\
`.computeIntensity`: The compute intensity, will always equal `.computeEffort / .data`.


!!! note
    Note that the `computeIntensity` doesn't necessarily make sense in the context of only operation costs.
    It will still work as intended when adding/subtracting to/from a `graph_cost` estimate.
"""
const CDCost =
    NamedTuple{(:data, :computeEffort, :computeIntensity),Tuple{Float64,Float64,Float64}}

function +(cost1::CDCost, cost2::CDCost)::CDCost
    d = cost1.data + cost2.data
    ce = computeEffort = cost1.computeEffort + cost2.computeEffort
    return (data = d, computeEffort = ce, computeIntensity = ce / d)::CDCost
end

function -(cost1::CDCost, cost2::CDCost)::CDCost
    d = cost1.data - cost2.data
    ce = computeEffort = cost1.computeEffort - cost2.computeEffort
    return (data = d, computeEffort = ce, computeIntensity = ce / d)::CDCost
end

function isless(cost1::CDCost, cost2::CDCost)::Bool
    return cost1.data + cost1.computeEffort < cost2.data + cost2.computeEffort
end

function zero(type::Type{CDCost})
    return (data = 0.0, computeEffort = 0.0, computeIntensity = 0.0)::CDCost
end

function typemax(type::Type{CDCost})
    return (data = Inf, computeEffort = Inf, computeIntensity = 0.0)::CDCost
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
        computeEffort = properties.computeEffort,
        computeIntensity = properties.computeIntensity,
    )::CDCost
end

function operation_effect(
    estimator::GlobalMetricEstimator,
    graph::DAG,
    operation::NodeReduction,
)
    s = length(operation.input) - 1
    return (
        data = s * -data(task(operation.input[1])),
        computeEffort = s * -compute_effort(task(operation.input[1])),
        computeIntensity = typeof(operation.input) <: DataTaskNode ? 0.0 : Inf,
    )::CDCost
end

function operation_effect(
    estimator::GlobalMetricEstimator,
    graph::DAG,
    operation::NodeSplit,
)
    s::Float64 = length(parents(operation.input)) - 1
    d::Float64 = s * data(task(operation.input))
    ce::Float64 = s * compute_effort(task(operation.input))
    return (data = d, computeEffort = ce, computeIntensity = ce / d)::CDCost
end

function String(::GlobalMetricEstimator)
    return "global_metric"
end
