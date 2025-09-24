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

    clean_node!.(Ref(dag), dag.dirty_nodes)
    empty!(dag.dirty_nodes)

    return dag.possible_operations
end
