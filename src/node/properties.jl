"""
    is_entry_node(node::Node)

Return whether this node is an entry node in its graph, i.e., it has no children.
"""
is_entry_node(node::Node) = length(node.children) == 0

"""
    is_exit_node(node::Node)

Return whether this node is an exit node of its graph, i.e., it has no parents.
"""
is_exit_node(node::Node)::Bool = length(node.parents) == 0

"""
    task(node::Node)

Return the node's task.
"""
function task(
        node::DataTaskNode{TaskType}
    )::TaskType where {TaskType <: AbstractDataTask}
    return node.task
end
function task(
        node::ComputeTaskNode{TaskType}
    )::TaskType where {TaskType <: AbstractComputeTask}
    return node.task
end

"""
    children(dag::DAG, node::Node)

Return node's children.

A node's children are its prerequisite nodes, nodes that need to execute before the task of this node.

A node's children are the nodes that must run before it.
"""
function children(dag::DAG, node::Union{DataTaskNode, ComputeTaskNode})
    return getindex.(Ref(dag.nodes), getindex.(node.children, 1))
end

"""
    parents(dag::DAG, node::Node)

Return the node's parents.

A node's parents are its subsequent nodes, nodes that need this node to execute.
"""
function parents(dag::DAG, node::Union{DataTaskNode, ComputeTaskNode})
    return getindex.(Ref(dag.nodes), node.parents)
end

"""
    siblings(dag::DAG, node::Node)

Return a vector of all siblings of this node.

A node's siblings are all children of any of its parents. The result contains no duplicates and includes the node itself.
"""
function siblings(dag::DAG, node::Node)
    result = Set{Node}()
    push!(result, node)
    for parent in parents(dag, node)
        union!(result, getindex.(children(dag, parent), 1))
    end

    return result
end

"""
    partners(dag::DAG, node::Node)

Return a vector of all partners of this node.

A node's partners are all parents of any of its children. The result contains no duplicates and includes the node itself.

!!! note
    This is very slow when there are multiple children with many parents.
    This is less of a problem in [`siblings(node::Node)`](@ref) because (depending on the model) there are no nodes with a large number of children, or only a single one.
"""
function partners(dag::DAG, node::Node)
    result = Set{Node}()
    push!(result, node)
    for child in children(dag, node)
        union!(result, parents(dag, child))
    end

    return result
end

"""
    partners(dag::DAG, node::Node, set::Set{Node})

Alternative version to [`partners(node::Node)`](@ref), avoiding allocation of a new set. Works on the given set and returns `nothing`.
"""
function partners(dag::DAG, node::Node, set::Set{Node})
    push!(set, node)
    for child in children(dag, node)
        union!(set, parents(dag, child))
    end
    return nothing
end

"""
    is_parent(dag::DAG, potential_parent::Node, node::Node)

Return whether the `potential_parent` is a parent of `node`.
"""
function is_parent(dag::DAG, potential_parent::Node, node::Node)::Bool
    return potential_parent in parents(dag, node)
end

"""
    is_child(dag::DAG, potential_child::Node, node::Node)

Return whether the `potential_child` is a child of `node`.
"""
function is_child(dag::DAG, potential_child::Node, node::Node)::Bool
    return potential_child in children(dag, node)
end
