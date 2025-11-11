using DataStructures
using UUIDs

function is_connected(dag::DAG)
    node_queue = Deque{UUID}()
    push!(node_queue, exit_node(dag).id)
    seen_nodes = Set{UUID}()

    while !isempty(node_queue)
        current = pop!(node_queue)
        push!(seen_nodes, current)

        for (child_id, index) in dag.nodes[current].children
            push!(node_queue, child_id)
        end
    end

    return length(seen_nodes) == length(dag.nodes)
end

function is_valid(dag::DAG)
    for (id, node) in dag.nodes
        @assert is_valid(dag, node)
    end

    for op in dag.operations_to_apply
        @assert is_valid(dag, op)
    end

    for nr in dag.possible_operations.node_reductions
        @assert is_valid(dag, nr)
    end
    for ns in dag.possible_operations.node_splits
        @assert is_valid(dag, ns)
    end

    for node_id in dag.dirty_nodes
        node = dag.nodes[node_id]
        @assert node in dag "Dirty Node is not part of the graph!"
    end

    @assert is_connected(dag) "Graph is not connected!"

    return true
end
