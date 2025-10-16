"""
    ReductionOptimizer

An optimizer that simply applies an available [`NodeReduction`](@ref) on each step. It implements [`optimize_to_fixpoint!`](@ref). The fixpoint is reached when there are no more possible [`NodeReduction`](@ref)s in the graph.

See also: [`SplitOptimizer`](@ref)
"""
struct ReductionOptimizer <: AbstractOptimizer end

function optimize_step!(optimizer::ReductionOptimizer, graph::DAG)
    # generate all options
    ops = operations(graph)
    if fixpoint_reached(optimizer, graph)
        return false
    end

    push_operation!(graph, first(ops.node_reductions))

    return true
end

function fixpoint_reached(optimizer::ReductionOptimizer, graph::DAG)
    ops = operations(graph)
    return isempty(ops.node_reductions)
end

function optimize_to_fixpoint!(optimizer::ReductionOptimizer, graph::DAG)
    while !fixpoint_reached(optimizer, graph)
        optimize_step!(optimizer, graph)
    end
    return nothing
end

function Base.print(io::IO, ::ReductionOptimizer)
    print(io, "reduction_optimizer")
    return nothing
end
