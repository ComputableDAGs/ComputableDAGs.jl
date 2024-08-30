"""
    is_valid_node(graph::DAG, node::Node)

Verify that a given node is valid in the graph. Call like `@test is_valid_node(g, n)`. Uses `@assert` to fail if something is invalid but also provide an error message.

This function is very performance intensive and should only be used when testing or debugging.

See also this function's specific versions for the concrete Node types [`is_valid(graph::DAG, node::ComputeTaskNode)`](@ref) and [`is_valid(graph::DAG, node::DataTaskNode)`](@ref).
"""
function is_valid_node(graph::DAG, node::Node)
    @assert node in graph "Node is not part of the given graph!"

    for parent in node.parents
        @assert typeof(parent) != typeof(node) "Node's type is the same as its parent's!"
        @assert parent in graph "Node's parent is not in the same graph!"
        @assert node in parent.children "Node is not a child of its parent!"
    end

    for child in node.children
        @assert typeof(child) != typeof(node) "Node's type is the same as its child's!"
        @assert child in graph "Node's child is not in the same graph!"
        @assert node in child.parents "Node is not a parent of its child!"
    end

    #=if !ismissing(node.nodeReduction)
        @assert is_valid(graph, node.nodeReduction)
    end
    if !ismissing(node.nodeSplit)
        @assert is_valid(graph, node.nodeSplit)
    end=#

    return true
end

"""
    is_valid(graph::DAG, node::ComputeTaskNode)

Verify that the given compute node is valid in the graph. Call with `@assert` or `@test` when testing or debugging.

This also calls [`is_valid_node(graph::DAG, node::Node)`](@ref).
"""
function is_valid(graph::DAG, node::ComputeTaskNode)
    @assert is_valid_node(graph, node)

    return true
end

"""
    is_valid(graph::DAG, node::DataTaskNode)

Verify that the given compute node is valid in the graph. Call with `@assert` or `@test` when testing or debugging.

This also calls [`is_valid_node(graph::DAG, node::Node)`](@ref).
"""
function is_valid(graph::DAG, node::DataTaskNode)
    @assert is_valid_node(graph, node)

    return true
end
