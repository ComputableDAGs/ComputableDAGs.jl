"""
    push_operation!(graph::DAG, operation::Operation)

Apply a new operation to the graph.

See also: [`DAG`](@ref), [`pop_operation!`](@ref)
"""
function push_operation!(graph::DAG, operation::Operation)
    # 1.: Add the operation to the DAG
    push!(graph.operationsToApply, operation)

    return nothing
end

"""
    pop_operation!(graph::DAG)

Revert the latest applied operation on the graph.

See also: [`DAG`](@ref), [`push_operation!`](@ref)
"""
function pop_operation!(graph::DAG)
    # 1.: Remove the operation from the appliedChain of the DAG
    if !isempty(graph.operationsToApply)
        pop!(graph.operationsToApply)
    elseif !isempty(graph.appliedOperations)
        appliedOp = pop!(graph.appliedOperations)
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
can_pop(graph::DAG) = !isempty(graph.operationsToApply) || !isempty(graph.appliedOperations)

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
