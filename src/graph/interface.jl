"""
    push_operation!(graph::DAG, operation::Operation)

Apply a new operation to the graph.

See also: [`DAG`](@ref), [`pop_operation!`](@ref)
"""
function push_operation!(graph::DAG, operation::Operation)
    # 1.: Add the operation to the DAG
    push!(graph.operations_to_apply, operation)

    return nothing
end

"""
    pop_operation!(graph::DAG)

Revert the latest applied operation on the graph.

See also: [`DAG`](@ref), [`push_operation!`](@ref)
"""
function pop_operation!(graph::DAG)
    # 1.: Remove the operation from the appliedChain of the DAG
    if !isempty(graph.operations_to_apply)
        pop!(graph.operations_to_apply)
    elseif !isempty(graph.applied_operations)
        appliedOp = pop!(graph.applied_operations)
        revert_operation!(graph, appliedOp)
    else
        error("No more operations to pop!")
    end

    return nothing
end

"""
    can_pop(graph::DAG)

Return `true` if [`pop_operation!`](@ref) is possible, `false` otherwise.
"""
can_pop(graph::DAG) =
    !isempty(graph.operations_to_apply) || !isempty(graph.applied_operations)

"""
    reset_graph!(graph::DAG)

Reset the graph to its initial state with no operations applied.
"""
function reset_graph!(graph::DAG)
    while (can_pop(graph))
        pop_operation!(graph)
    end

    return nothing
end
