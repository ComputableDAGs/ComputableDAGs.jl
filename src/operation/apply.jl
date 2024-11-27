"""
    apply_all!(graph::DAG)

Apply all unapplied operations in the DAG. Is automatically called in all functions that require the latest state of the [`DAG`](@ref).
"""
function apply_all!(graph::DAG)
    while !isempty(graph.operations_to_apply)
        # get next operation to apply from front of the deque
        op = popfirst!(graph.operations_to_apply)

        # apply it
        appliedOp = apply_operation!(graph, op)

        # push to the end of the applied_operations deque
        push!(graph.applied_operations, appliedOp)
    end
    return nothing
end

"""
    apply_operation!(graph::DAG, operation::Operation)

Fallback implementation of apply_operation! for unimplemented operation types, throwing an error.
"""
function apply_operation!(graph::DAG, operation::Operation)
    return error("unknown operation type")
end

"""
    apply_operation!(graph::DAG, operation::NodeReduction)

Apply the given [`NodeReduction`](@ref) to the graph. Generic wrapper around [`node_reduction!`](@ref).

Return an [`AppliedNodeReduction`](@ref) object generated from the graph's [`Diff`](@ref).
"""
function apply_operation!(graph::DAG, operation::NodeReduction)
    diff = node_reduction!(graph, operation.input)

    graph.properties += GraphProperties(diff)

    return AppliedNodeReduction(operation, diff)
end

"""
    apply_operation!(graph::DAG, operation::NodeSplit)

Apply the given [`NodeSplit`](@ref) to the graph. Generic wrapper around [`node_split!`](@ref).

Return an [`AppliedNodeSplit`](@ref) object generated from the graph's [`Diff`](@ref).
"""
function apply_operation!(graph::DAG, operation::NodeSplit)
    diff = node_split!(graph, operation.input)

    graph.properties += GraphProperties(diff)

    return AppliedNodeSplit(operation, diff)
end

"""
    revert_operation!(graph::DAG, operation::AppliedOperation)

Fallback implementation of operation reversion for unimplemented operation types, throwing an error.
"""
function revert_operation!(graph::DAG, operation::AppliedOperation)
    return error("unknown operation type")
end

"""
    revert_operation!(graph::DAG, operation::AppliedNodeReduction)

Revert the applied node reduction on the graph. Return the original [`NodeReduction`](@ref) operation.
"""
function revert_operation!(graph::DAG, operation::AppliedNodeReduction)
    revert_diff!(graph, operation.diff)
    return operation.operation
end

"""
    revert_operation!(graph::DAG, operation::AppliedNodeSplit)

Revert the applied node split on the graph. Return the original [`NodeSplit`](@ref) operation.
"""
function revert_operation!(graph::DAG, operation::AppliedNodeSplit)
    revert_diff!(graph, operation.diff)
    return operation.operation
end

"""
    revert_diff!(graph::DAG, diff::Diff)

Revert the given diff on the graph. Used to revert the individual [`AppliedOperation`](@ref)s with [`revert_operation!`](@ref).
"""
function revert_diff!(graph::DAG, diff::Diff)
    # add removed nodes, remove added nodes, same for edges
    # note the order
    for edge in diff.addedEdges
        _remove_edge!(graph, edge.edge[1], edge.edge[2]; track=false)
    end
    for node in diff.addedNodes
        _remove_node!(graph, node; track=false)
    end

    for node in diff.removedNodes
        _insert_node!(graph, node; track=false)
    end
    for edge in diff.removedEdges
        _insert_edge!(graph, edge.edge[1], edge.edge[2], edge.index; track=false)
    end

    graph.properties -= GraphProperties(diff)

    return nothing
end

"""
    node_reduction!(graph::DAG, nodes::Vector{Node})

Reduce the given nodes together into one node, return the applied difference to the graph.

For details see [`NodeReduction`](@ref).
"""
function node_reduction!(graph::DAG, nodes::Vector{Node})
    @assert is_valid_node_reduction_input(graph, nodes)

    # clear snapshot
    get_snapshot_diff(graph)

    n1 = nodes[1]
    n1_children = copy(children(n1))

    n1_parents = Set(parents(n1))

    # set of the new parents of n1 together with the index of the child nodes
    new_parents = Set{Tuple{Node,Int}}()

    # names of the previous children that n1 now replaces per parent
    new_parents_child_names = Dict{Node,Symbol}()

    # remove all of the nodes' parents and children and the nodes themselves (except for first node)
    for i in 2:length(nodes)
        n = nodes[i]
        for (child, index) in n1_children
            # no need to care about the indices here
            _remove_edge!(graph, child, n)
        end

        for parent in copy(parents(n))
            removed_index = _remove_edge!(graph, n, parent)

            # collect all parents
            push!(new_parents, (parent, removed_index))
            new_parents_child_names[parent] = Symbol(to_var_name(n.id))
        end

        _remove_node!(graph, n)
    end

    for (parent, index) in new_parents
        # now add parents of all input nodes to n1 without duplicates
        if !(parent in n1_parents)
            # don't double insert edges
            _insert_edge!(graph, n1, parent, index)
        end
    end

    return get_snapshot_diff(graph)
end

"""
    node_split!(graph::DAG, n1::Node)

Split the given node into one node per parent, return the applied difference to the graph.

For details see [`NodeSplit`](@ref).
"""
function node_split!(
    graph::DAG, n1::Union{DataTaskNode{TaskType},ComputeTaskNode{TaskType}}
) where {TaskType<:AbstractTask}
    @assert is_valid_node_split_input(graph, n1)

    # clear snapshot
    get_snapshot_diff(graph)

    n1_parents = copy(parents(n1))
    n1_children = copy(children(n1))

    for parent in n1_parents
        _remove_edge!(graph, n1, parent)
    end
    for (child, index) in n1_children
        _remove_edge!(graph, child, n1)
    end
    _remove_node!(graph, n1)

    for parent in n1_parents
        n_copy = copy(n1)

        _insert_node!(graph, n_copy)
        _insert_edge!(graph, n_copy, parent)

        for (child, index) in n1_children
            _insert_edge!(graph, child, n_copy)
        end
    end

    return get_snapshot_diff(graph)
end
