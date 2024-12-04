"""
    SplitOptimizer

An optimizer that simply applies an available [`NodeSplit`](@ref) on each step. It implements [`optimize_to_fixpoint!`](@ref). The fixpoint is reached when there are no more possible [`NodeSplit`](@ref)s in the graph.

See also: [`ReductionOptimizer`](@ref)
"""
struct SplitOptimizer <: AbstractOptimizer end

function optimize_step!(optimizer::SplitOptimizer, graph::DAG)
    # generate all options
    operations = get_operations(graph)
    if fixpoint_reached(optimizer, graph)
        return false
    end

    push_operation!(graph, first(operations.node_splits))

    return true
end

function fixpoint_reached(optimizer::SplitOptimizer, graph::DAG)
    operations = get_operations(graph)
    return isempty(operations.node_splits)
end

function optimize_to_fixpoint!(optimizer::SplitOptimizer, graph::DAG)
    while !fixpoint_reached(optimizer, graph)
        optimize_step!(optimizer, graph)
    end
    return nothing
end

function String(::SplitOptimizer)
    return "split_optimizer"
end
