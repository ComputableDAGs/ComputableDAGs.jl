"""
    push_operation!(dag::DAG, operation::Operation)

Apply a new operation to the graph.

See also: [`DAG`](@ref), [`pop_operation!`](@ref)
"""
function push_operation!(dag::DAG, operation::Operation)
    # 1.: Add the operation to the DAG
    push!(dag.operations_to_apply, operation)

    return nothing
end

"""
    pop_operation!(dag::DAG)

Revert the latest applied operation on the graph.

See also: [`DAG`](@ref), [`push_operation!`](@ref)
"""
function pop_operation!(dag::DAG)
    # 1.: Remove the operation from the appliedChain of the DAG
    if !isempty(dag.operations_to_apply)
        pop!(dag.operations_to_apply)
    elseif !isempty(dag.applied_operations)
        appliedOp = pop!(dag.applied_operations)
        revert_operation!(dag, appliedOp)
    else
        error("No more operations to pop!")
    end

    return nothing
end

"""
    can_pop(dag::DAG)

Return `true` if [`pop_operation!`](@ref) is possible, `false` otherwise.
"""
can_pop(dag::DAG) =
    !isempty(dag.operations_to_apply) || !isempty(dag.applied_operations)

"""
    reset_graph!(dag::DAG)

Reset the graph to its initial state with no operations applied.
"""
function reset_graph!(dag::DAG)
    while (can_pop(dag))
        pop_operation!(dag)
    end

    return nothing
end
