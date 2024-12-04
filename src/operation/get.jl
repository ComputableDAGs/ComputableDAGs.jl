# function to return the possible operations of a graph

using Base.Threads

"""
    get_operations(graph::DAG)

Return the [`PossibleOperations`](@ref) of the graph at the current state.
"""
function get_operations(graph::DAG)
    apply_all!(graph)

    if isempty(graph.possible_operations)
        generate_operations(graph)
    end

    clean_node!.(Ref(graph), graph.dirty_nodes)
    empty!(graph.dirty_nodes)

    return graph.possible_operations
end
