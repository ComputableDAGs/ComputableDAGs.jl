"""
    get_properties(dag::DAG)

Return the graph's [`GraphProperties`](@ref).
"""
function get_properties(dag::DAG)
    # make sure the graph is fully generated
    apply_all!(dag)

    properties = GraphProperties(dag)

    return properties
end

"""
    get_exit_node(dag::DAG)

Return the graph's exit node. This assumes the graph only has a single exit node. If the graph has multiple exit nodes, the one encountered first will be returned.
"""
function get_exit_node(dag::DAG)
    for (id, node) in dag.nodes
        if (is_exit_node(node))
            return node
        end
    end
    return @assert false "The given graph has no exit node! It is either empty or not acyclic!"
end

"""
    get_entry_nodes(dag::DAG)

Return a vector of the graph's entry nodes.
"""
function get_entry_nodes(dag::DAG)
    apply_all!(dag)
    result = Vector{Node}()
    for (id, node) in dag.nodes
        if (is_entry_node(node))
            push!(result, node)
        end
    end
    return result
end

"""
    operation_stack_length(dag::DAG)

Return the number of operations applied to the graph.
"""
function operation_stack_length(dag::DAG)
    return length(dag.applied_operations) + length(dag.operations_to_apply)
end
