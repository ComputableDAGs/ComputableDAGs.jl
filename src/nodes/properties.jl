"""
    is_entry_node(node::Node)

Return whether this node is an entry node in the dependency graph, i.e., it has no dependencies.

Note that this does not check whether the node is part of a [`ComputableDAG`](@ref) in the first place, so for a new and empty node, it always returns true.
"""
function is_entry_node(node::Node)
    return isempty(node.dependencies)
end

"""
    is_exit_node(node::Node)

Return whether this node is an exit node in the dependency graph, i.e., it has no dependents.

Note that this does not check whether the node is part of a [`ComputableDAG`](@ref) in the first place, so for a new and empty node, it always returns true.
"""
function is_exit_node(node::Node)
    return isempty(node.dependents)
end

"""
    task(node::Node)

Return the node's task.
"""
function task(node::Node)
    return node.task
end
