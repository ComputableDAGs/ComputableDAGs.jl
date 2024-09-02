using Random

"""
    RandomWalkOptimizer

An optimizer that randomly pushes or pops operations. It doesn't optimize in any direction and is useful mainly for testing purposes.

This algorithm never reaches a fixpoint, so it does not implement [`optimize_to_fixpoint!`](@ref).
"""
struct RandomWalkOptimizer <: AbstractOptimizer
    rng::AbstractRNG
end

function optimize_step!(optimizer::RandomWalkOptimizer, graph::DAG)
    operations = get_operations(graph)

    if sum(length(operations)) == 0 &&
        length(graph.appliedOperations) + length(graph.operationsToApply) == 0
        # in case there are zero operations possible at all on the graph
        return false
    end

    r = optimizer.rng
    # try until something was applied or popped
    while true
        # choose push or pop
        if rand(r, Bool)
            # push

            # choose one of split/reduce
            option = rand(r, 1:2)
            if option == 1 && !isempty(operations.nodeReductions)
                push_operation!(graph, rand(r, collect(operations.nodeReductions)))
                return true
            elseif option == 2 && !isempty(operations.nodeSplits)
                push_operation!(graph, rand(r, collect(operations.nodeSplits)))
                return true
            end
        else
            # pop
            if (can_pop(graph))
                pop_operation!(graph)
                return true
            end
        end
    end
end

function String(::RandomWalkOptimizer)
    return "random_walker"
end
