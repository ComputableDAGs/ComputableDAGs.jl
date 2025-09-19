"""
    AbstractEstimator

Abstract base type for an estimator. An estimator estimates the cost of a graph or the difference an operation applied to a graph will make to its cost.

Interface functions are
- [`graph_cost`](@ref)
- [`operation_effect`](@ref)
"""
abstract type AbstractEstimator end

"""
    cost_type(estimator::AbstractEstimator)

Interface function returning a specific estimator's cost type, i.e., the type returned by its implementation of [`graph_cost`](@ref) and [`operation_effect`](@ref).
"""
function cost_type end

"""
    graph_cost(estimator::AbstractEstimator, graph::DAG)

Get the total estimated cost of the graph. The cost's data type can be chosen by the implementation, but must have a usable lessthan comparison operator (<), basic math operators (+, -) and an implementation of `zero()` and `typemax()`.
"""
function graph_cost end

"""
    operation_effect(estimator::AbstractEstimator, graph::DAG, operation::Operation)

Get the estimated effect on the cost of the graph, such that `graph_cost(estimator, graph) + operation_effect(estimator, graph, operation) ~= graph_cost(estimator, graph_with_operation_applied)`. There is no hard requirement for this, but the better the estimate, the better an optimization algorithm will be.

!!! note
    There is a default implementation of this function, applying the operation, calling [`graph_cost`](@ref), then popping the operation again.

    It can be much faster to overload this function for a specific estimator and directly compute the effects from the operation if possible.
"""
function operation_effect(estimator::AbstractEstimator, graph::DAG, operation::Operation)
    # This is currently not stably working, see issue #16
    cost = graph_cost(estimator, graph)
    push_operation!(graph, operation)
    cost_after = graph_cost(estimator, graph)
    pop_operation!(graph)
    return cost_after - cost
end
