# These are functions for "cleaning" nodes, i.e. regenerating the possible operations for a node

"""
    find_reductions!(dag::DAG, node::Node)

Find node reductions involving the given node. The function pushes the found [`NodeReduction`](@ref) (if any) everywhere it needs to be and returns nothing.
"""
function find_reductions!(dag::DAG, node::Node)
    reduction_vector = UUID[]
    # possible reductions are with nodes that are partners, i.e. parents of children
    partners_ = partners(dag, node)
    delete!(partners_, node)
    for partner in partners_
        @assert haskey(dag.nodes, partner.id)
        if can_reduce(node, partner)
            if isempty(reduction_vector)
                # only when there's at least one reduction partner, insert the vector
                push!(reduction_vector, node.id)
            end

            push!(reduction_vector, partner.id)
        end
    end

    if !isempty(reduction_vector)
        nr = NodeReduction(reduction_vector)
        push!(dag.possible_operations.node_reductions, nr)
    end

    return nothing
end

"""
    find_splits!(dag::DAG, node::Node)

Find the node split of the given node. The function pushes the found [`NodeSplit`](@ref) (if any) everywhere it needs to be and returns nothing.
"""
function find_splits!(dag::DAG, node::Node)
    if (can_split(node))
        ns = NodeSplit(node.id)
        push!(dag.possible_operations.node_splits, ns)
    end

    return nothing
end

"""
    clean_node!(dag::DAG, node_id::UUID)

Sort this node's parent and child sets, then find reductions and splits involving it. Needs to be called after the node was changed in some way.
"""
function clean_node!(
        dag::DAG, node_id::UUID
    )
    if !haskey(dag.nodes, node_id)
        # sometimes the dirty node was already deleted
        return nothing
    end

    node = dag.nodes[node_id]
    sort_node!(node)

    find_reductions!(dag, node)
    find_splits!(dag, node)

    return nothing
end
