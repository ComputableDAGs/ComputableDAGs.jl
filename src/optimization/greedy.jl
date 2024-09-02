"""
    GreedyOptimizer

An implementation of the greedy optimization algorithm, simply choosing the best next option evaluated with the given estimator.

The fixpoint is reached when any leftover operation would increase the graph's total cost according to the given estimator.
"""
struct GreedyOptimizer{EstimatorType<:AbstractEstimator} <: AbstractOptimizer
    estimator::EstimatorType
end

function optimize_step!(optimizer::GreedyOptimizer, graph::DAG)
    # generate all options
    operations = get_operations(graph)
    if isempty(operations)
        return false
    end

    result = nothing

    lowestCost = reduce(
        (acc, op) -> begin
            op_cost = operation_effect(optimizer.estimator, graph, op)
            if isless(op_cost, acc)
                result = op
                return op_cost
            end
            return acc
        end,
        operations;
        init=typemax(cost_type(optimizer.estimator)),
    )

    if lowestCost > zero(cost_type(optimizer.estimator))
        return false
    end

    push_operation!(graph, result)

    return true
end

function fixpoint_reached(optimizer::GreedyOptimizer, graph::DAG)
    # generate all options
    operations = get_operations(graph)
    if isempty(operations)
        return true
    end

    lowestCost = reduce(
        (acc, op) -> begin
            op_cost = operation_effect(optimizer.estimator, graph, op)
            if isless(op_cost, acc)
                return op_cost
            end
            return acc
        end,
        operations;
        init=typemax(cost_type(optimizer.estimator)),
    )

    if lowestCost > zero(cost_type(optimizer.estimator))
        return true
    end

    return false
end

function optimize_to_fixpoint!(optimizer::GreedyOptimizer, graph::DAG)
    while optimize_step!(optimizer, graph)
    end
    return nothing
end

function String(optimizer::GreedyOptimizer)
    return "greedy_optimizer_$(optimizer.estimator)"
end
