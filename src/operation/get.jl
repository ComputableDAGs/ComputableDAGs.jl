# function to return the possible operations of a graph

using Base.Threads

"""
    get_operations(dag::DAG)

Return the [`PossibleOperations`](@ref) of the graph at the current state.
"""
function get_operations(dag::DAG)
    apply_all!(dag)

    if isempty(dag.possible_operations)
        generate_operations(dag)
    end

    # remove node reductions/splits, where at least one of the inputs is a dirty node
    filter!(
        nr -> begin
            return !any(id -> id in dag.dirty_nodes, nr.input)
        end, dag.possible_operations.node_reductions
    )
    filter!(
        ns -> begin
            return !(ns.input in dag.dirty_nodes)
        end, dag.possible_operations.node_splits
    )

    clean_node!.(Ref(dag), dag.dirty_nodes)
    empty!(dag.dirty_nodes)

    return dag.possible_operations
end
