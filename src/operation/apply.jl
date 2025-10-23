"""
    apply_all!(dag::DAG)

Apply all unapplied operations in the DAG. Is automatically called in all functions that require the latest state of the [`DAG`](@ref).
"""
function apply_all!(dag::DAG)
    while !isempty(dag.operations_to_apply)
        # get next operation to apply from front of the deque
        op = popfirst!(dag.operations_to_apply)

        # apply it
        applied_op = apply_operation!(dag, op)

        # push to the end of the applied_operations deque
        push!(dag.applied_operations, applied_op)
    end
    return nothing
end

"""
    apply_operation!(dag::DAG, operation::Operation)

Fallback implementation of apply_operation! for unimplemented operation types, throwing an error.
"""
function apply_operation!(dag::DAG, operation::Operation)
    return error("unknown operation type")
end

"""
    apply_operation!(dag::DAG, operation::NodeReduction)

Apply the given [`NodeReduction`](@ref) to the graph. Generic wrapper around [`node_reduction!`](@ref).

Return an [`AppliedNodeReduction`](@ref) object generated from the graph's [`Diff`](@ref).
"""
function apply_operation!(dag::DAG, operation::NodeReduction)
    diff = node_reduction!(dag, getindex.(Ref(dag.nodes), operation.input))

    return AppliedNodeReduction(operation, diff)
end

"""
    apply_operation!(dag::DAG, operation::NodeSplit)

Apply the given [`NodeSplit`](@ref) to the graph. Generic wrapper around [`node_split!`](@ref).

Return an [`AppliedNodeSplit`](@ref) object generated from the graph's [`Diff`](@ref).
"""
function apply_operation!(dag::DAG, operation::NodeSplit)
    diff = node_split!(dag, dag.nodes[operation.input])

    return AppliedNodeSplit(operation, diff)
end

"""
    revert_operation!(dag::DAG, operation::AppliedOperation)

Fallback implementation of operation reversion for unimplemented operation types, throwing an error.
"""
function revert_operation!(dag::DAG, operation::AppliedOperation)
    return error("unknown operation type")
end

"""
    revert_operation!(dag::DAG, operation::AppliedNodeReduction)

Revert the applied node reduction on the graph. Return the original [`NodeReduction`](@ref) operation.
"""
function revert_operation!(dag::DAG, operation::AppliedNodeReduction)
    revert_diff!(dag, operation.diff)
    return operation.operation
end

"""
    revert_operation!(dag::DAG, operation::AppliedNodeSplit)

Revert the applied node split on the graph. Return the original [`NodeSplit`](@ref) operation.
"""
function revert_operation!(dag::DAG, operation::AppliedNodeSplit)
    revert_diff!(dag, operation.diff)
    return operation.operation
end

"""
    revert_diff!(dag::DAG, diff::Diff)

Revert the given diff on the graph. Used to revert the individual [`AppliedOperation`](@ref)s with [`revert_operation!`](@ref).
"""
function revert_diff!(dag::DAG, diff::Diff)
    # add removed nodes, remove added nodes, same for edges
    # note the order
    for node in diff.removed_nodes
        _insert_node!(dag, node; track = false)
    end

    for edge in diff.added_edges
        _remove_edge!(dag, dag.nodes[edge.edge[1]], dag.nodes[edge.edge[2]]; track = false)
    end

    for node in diff.added_nodes
        _remove_node!(dag, node; track = false)
    end

    for edge in diff.removed_edges
        _insert_edge!(dag, dag.nodes[edge.edge[1]], dag.nodes[edge.edge[2]], edge.index; track = false)
    end

    return nothing
end

"""
    node_reduction!(dag::DAG, nodes::Vector{Node})

Reduce the given nodes together into one node, return the applied difference to the graph.

For details see [`NodeReduction`](@ref).
"""
function node_reduction!(dag::DAG, nodes::Vector{NodeType}) where {NodeType <: Node}
    @assert is_valid_node_reduction_input(dag, nodes)

    # clear snapshot
    snapshot_diff(dag)

    n1 = nodes[1]
    n1_children = children(dag, n1)

    n1_parents = Set(parents(dag, n1))

    # set of the new parents of n1 together with the index of the child nodes
    new_parents = Set{Tuple{Node, Int}}()

    # names of the previous children that n1 now replaces per parent
    new_parents_child_names = Dict{Node, Symbol}()

    # remove all of the nodes' parents and children and the nodes themselves (except for first node)
    for i in 2:length(nodes)
        n = nodes[i]
        for child in n1_children
            # no need to care about the indices here
            _remove_edge!(dag, child, n)
        end

        for parent in copy(parents(dag, n))
            removed_index = _remove_edge!(dag, n, parent)

            # collect all parents
            push!(new_parents, (parent, removed_index))
            new_parents_child_names[parent] = Symbol(to_var_name(n.id))
        end

        _remove_node!(dag, n)
    end

    for (parent, index) in new_parents
        # now add parents of all input nodes to n1 without duplicates
        if !(parent in n1_parents)
            # don't double insert edges
            _insert_edge!(dag, n1, parent, index)
        end
    end

    return snapshot_diff(dag)
end

"""
    node_split!(dag::DAG, n1::Node)

Split the given node into one node per parent, return the applied difference to the graph.

For details see [`NodeSplit`](@ref).
"""
function node_split!(
        dag::DAG, n1::NodeType
    ) where {NodeType <: Node}
    @assert is_valid_node_split_input(dag, n1)

    # clear snapshot
    snapshot_diff(dag)

    n1_parents = parents(dag, n1)
    local parent_indices = Dict()
    n1_children = copy(n1.children)

    for parent in n1_parents
        parent_indices[parent] = _remove_edge!(dag, n1, parent)
    end
    for (child_id, index) in n1_children
        child = dag.nodes[child_id]
        @assert index == _remove_edge!(dag, child, n1)
    end
    _remove_node!(dag, n1)

    for parent in n1_parents
        n_copy = copy(n1)

        _insert_node!(dag, n_copy)
        _insert_edge!(dag, n_copy, parent, parent_indices[parent])

        for (child_id, index) in n1_children
            child = dag.nodes[child_id]
            _insert_edge!(dag, child, n_copy, index)
        end
    end

    return snapshot_diff(dag)
end
