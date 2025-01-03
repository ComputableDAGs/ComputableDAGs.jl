# These are functions for "cleaning" nodes, i.e. regenerating the possible operations for a node

"""
    find_reductions!(graph::DAG, node::Node)

Find node reductions involving the given node. The function pushes the found [`NodeReduction`](@ref) (if any) everywhere it needs to be and returns nothing.
"""
function find_reductions!(graph::DAG, node::Node)
    # there can only be one reduction per node, avoid adding duplicates
    if !ismissing(node.node_reduction)
        return nothing
    end

    reductionVector = nothing
    # possible reductions are with nodes that are partners, i.e. parents of children
    partners_ = partners(node)
    delete!(partners_, node)
    for partner in partners_
        @assert partner in graph.nodes
        if can_reduce(node, partner)
            if reductionVector === nothing
                # only when there's at least one reduction partner, insert the vector
                reductionVector = Vector{Node}()
                push!(reductionVector, node)
            end

            push!(reductionVector, partner)
        end
    end

    if reductionVector !== nothing
        nr = NodeReduction(reductionVector)
        push!(graph.possible_operations.node_reductions, nr)
        for node in reductionVector
            if !ismissing(node.node_reduction)
                # it can happen that the dirty node becomes part of an existing NodeReduction and overrides those ones now
                # this is only a problem insofar the existing NodeReduction has to be deleted and replaced also in the possible_operations
                invalidate_caches!(graph, node.node_reduction)
            end
            node.node_reduction = nr
        end
    end

    return nothing
end

"""
    find_splits!(graph::DAG, node::Node)

Find the node split of the given node. The function pushes the found [`NodeSplit`](@ref) (if any) everywhere it needs to be and returns nothing.
"""
function find_splits!(graph::DAG, node::Node)
    if !ismissing(node.node_split)
        return nothing
    end

    if (can_split(node))
        ns = NodeSplit(node)
        push!(graph.possible_operations.node_splits, ns)
        node.node_split = ns
    end

    return nothing
end

"""
    clean_node!(graph::DAG, node::Node)

Sort this node's parent and child sets, then find reductions and splits involving it. Needs to be called after the node was changed in some way.
"""
function clean_node!(
    graph::DAG, node::Union{DataTaskNode{TaskType},ComputeTaskNode{TaskType}}
) where {TaskType<:AbstractTask}
    sort_node!(node)

    find_reductions!(graph, node)
    find_splits!(graph, node)

    return nothing
end
