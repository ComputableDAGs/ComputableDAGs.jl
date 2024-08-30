"""
    get_properties(graph::DAG)

Return the graph's [`GraphProperties`](@ref).
"""
function get_properties(graph::DAG)
    # make sure the graph is fully generated
    apply_all!(graph)

    # TODO: tests stop working without the if condition, which means there is probably a bug in the lazy evaluation and in the tests
    if (graph.properties.computeEffort <= 0.0)
        graph.properties = GraphProperties(graph)
    end

    return graph.properties
end

"""
    get_exit_node(graph::DAG)

Return the graph's exit node. This assumes the graph only has a single exit node. If the graph has multiple exit nodes, the one encountered first will be returned.
"""
function get_exit_node(graph::DAG)
    for node in graph.nodes
        if (is_exit_node(node))
            return node
        end
    end
    @assert false "The given graph has no exit node! It is either empty or not acyclic!"
end

"""
    get_entry_nodes(graph::DAG)

Return a vector of the graph's entry nodes.
"""
function get_entry_nodes(graph::DAG)
    apply_all!(graph)
    result = Vector{Node}()
    for node in graph.nodes
        if (is_entry_node(node))
            push!(result, node)
        end
    end
    return result
end

"""
    operation_stack_length(graph::DAG)

Return the number of operations applied to the graph.
"""
function operation_stack_length(graph::DAG)
    return length(graph.appliedOperations) + length(graph.operationsToApply)
end
