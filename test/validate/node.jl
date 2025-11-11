function is_valid_node(dag::DAG, node::Node)
    @assert node in dag "Node is not part of the given graph!"

    for parent_id in node.parents
        parent = dag.nodes[parent_id]
        @assert typeof(parent) != typeof(node) "Node's type is the same as its parent's!"
        @assert haskey(dag.nodes, parent_id) "Node's parent is not in the same graph!"
        @assert ComputableDAGs.is_child(dag, node, parent) "Node is not a child of its parent!"
    end

    for (child_id, index) in node.children
        child = dag.nodes[child_id]
        @assert typeof(child) != typeof(node) "Node's type is the same as its child's!"
        @assert haskey(dag.nodes, child_id) "Node's child is not in the same graph!"
        @assert ComputableDAGs.is_parent(dag, node, child) "Node is not a parent of its child!"
    end

    return true
end

function is_valid(dag::DAG, node::ComputableDAGs.ComputeTaskNode)
    @assert is_valid_node(dag, node)

    return true
end

function is_valid(dag::DAG, node::ComputableDAGs.DataTaskNode)
    @assert is_valid_node(dag, node)

    return true
end
