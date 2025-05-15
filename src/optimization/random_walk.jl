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
            length(graph.applied_operations) + length(graph.operations_to_apply) == 0
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
            if option == 1 && !isempty(operations.node_reductions)
                push_operation!(graph, rand(r, collect(operations.node_reductions)))
                return true
            elseif option == 2 && !isempty(operations.node_splits)
                push_operation!(graph, rand(r, collect(operations.node_splits)))
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
    return
end

function Base.print(io::IO, ::RandomWalkOptimizer)
    print(io, "random_walker")
    return nothing
end
