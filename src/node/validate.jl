"""
    is_valid_node(graph::DAG, node::Node)

Verify that a given node is valid in the graph. Call like `@test is_valid_node(g, n)`. Uses `@assert` to fail if something is invalid but also provide an error message.

This function is very performance intensive and should only be used when testing or debugging.

See also this function's specific versions for the concrete Node types [`is_valid(graph::DAG, node::ComputeTaskNode)`](@ref) and [`is_valid(graph::DAG, node::DataTaskNode)`](@ref).
"""
function is_valid_node(dag::DAG, node::Node)
    @assert node in dag "Node is not part of the given graph!"

    for parent_id in node.parents
        parent = dag.nodes[parent_id]
        @assert typeof(parent) != typeof(node) "Node's type is the same as its parent's!"
        @assert haskey(dag.nodes, parent_id) "Node's parent is not in the same graph!"
        @assert is_child(dag, node, parent) "Node is not a child of its parent!"
    end

    for (child_id, index) in node.children
        child = dag.nodes[child_id]
        @assert typeof(child) != typeof(node) "Node's type is the same as its child's!"
        @assert haskey(dag.nodes, child_id) "Node's child is not in the same graph!"
        @assert is_parent(dag, node, child) "Node is not a parent of its child!"
    end

    return true
end

"""
    is_valid(dag::DAG, node::ComputeTaskNode)

Verify that the given compute node is valid in the graph. Call with `@assert` or `@test` when testing or debugging.

This also calls [`is_valid_node(graph::DAG, node::Node)`](@ref).
"""
function is_valid(dag::DAG, node::ComputeTaskNode)
    @assert is_valid_node(dag, node)

    return true
end

"""
    is_valid(dag::DAG, node::DataTaskNode)

Verify that the given compute node is valid in the graph. Call with `@assert` or `@test` when testing or debugging.

This also calls [`is_valid_node(graph::DAG, node::Node)`](@ref).
"""
function is_valid(dag::DAG, node::DataTaskNode)
    @assert is_valid_node(dag, node)

    return true
end
