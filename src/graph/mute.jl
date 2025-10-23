# for graph mutating functions we need to do a few things
# 1: mute the graph (duh)
# 2: keep track of what was changed for the diff (if track == true)
# 3: invalidate operation caches

"""
    insert_node!(dag::DAG, node::Node)
    insert_node!(dag::DAG, task::AbstractTask, name::String="")

Insert the node into the graph or alternatively construct a node from the given task and insert it.
"""
function insert_node!(dag::DAG, node::Node)
    return _insert_node!(dag, node; track = false, invalidate_cache = false)
end
function insert_node!(dag::DAG, task::AbstractDataTask, name::String = "")
    return _insert_node!(dag, make_node(task, name); track = false, invalidate_cache = false)
end
function insert_node!(dag::DAG, task::AbstractComputeTask)
    return _insert_node!(dag, make_node(task); track = false, invalidate_cache = false)
end

"""
    insert_edge!(dag::DAG, node1::Node, node2::Node)

Insert the edge between node1 (child) and node2 (parent) into the graph.
"""
function insert_edge!(dag::DAG, node1::Node, node2::Node, index::Int = 0)
    return _insert_edge!(dag, node1, node2, index; track = false, invalidate_cache = false)
end

"""
    _insert_node!(dag::DAG, node::Node; track = true, invalidate_cache = true)

Insert the node into the graph.

!!! warning
    For creating new graphs, use the public version [`insert_node!`](@ref) instead which uses the defaults false for the keywords.

## Keyword Arguments
`track::Bool`: Whether to add the changes to the [`DAG`](@ref)'s [`Diff`](@ref). Should be set `false` in parsing or graph creation functions for performance.

`invalidate_cache::Bool`: Whether to invalidate caches associated with the changes. Should also be turned off for graph creation or parsing.

See also: [`_remove_node!`](@ref), [`_insert_edge!`](@ref), [`_remove_edge!`](@ref)
"""
function _insert_node!(dag::DAG, node::Node; track = true, invalidate_cache = true)
    #@info "inserting node $(node.id)"

    @assert !haskey(dag.nodes, node.id) "Node to insert already exists!"

    # 1: mute
    dag.nodes[node.id] = node

    # 2: keep track
    if (track)
        push!(dag.diff.added_nodes, node)
    end

    # 3: invalidate caches
    if (!invalidate_cache)
        return node
    end
    push!(dag.dirty_nodes, node.id)

    return node
end

function _insert_edge!(
        ::DAG, ::DataTaskNode, ::DataTaskNode, ::Int = 0; track = true, invalidate_cache = true
    )
    throw("trying to create an edge between two data nodes which is not allowed")
end

function _insert_edge!(
        ::DAG, ::ComputeTaskNode, ::ComputeTaskNode, ::Int = 0; track = true, invalidate_cache = true
    )
    throw("trying to create an edge between two compute nodes which is not allowed")
end

"""
    _insert_edge!(graph::DAG, node1::Node, node2::Node, index::Int=0; track = true, invalidate_cache = true)

Insert the edge between `node1` (child) and `node2` (parent) into the graph. An optional integer index can be given. The arguments of the function call that this node compiles to will then be ordered by these indices.

!!! warning
    For creating new graphs, use the public version [`insert_edge!`](@ref) instead which uses the defaults false for the keywords.

## Keyword Arguments
- `track::Bool`: Whether to add the changes to the [`DAG`](@ref)'s [`Diff`](@ref). Should be set `false` in parsing or graph creation functions for performance.
- `invalidate_cache::Bool`: Whether to invalidate caches associated with the changes. Should also be turned off for graph creation or parsing.

See also: [`_insert_node!`](@ref), [`_remove_node!`](@ref), [`_remove_edge!`](@ref)
"""
function _insert_edge!(
        dag::DAG, node1::Node, node2::Node, index::Int = 0; track = true, invalidate_cache = true
    )
    #@info "inserting edge $(node1.id) to $(node2.id)"

    @assert (node2 ∉ parents(dag, node1)) && (node1 ∉ children(dag, node2)) "Edge to insert already exists"

    # 1: mute
    # edge points from child to parent
    push!(node1.parents, node2.id)
    push!(node2.children, (node1.id, index))

    # 2: keep track
    if (track)
        push!(dag.diff.added_edges, make_edge(node1, node2, index))
    end

    # 3: invalidate caches
    if (!invalidate_cache)
        return nothing
    end

    push!(dag.dirty_nodes, node1.id)
    push!(dag.dirty_nodes, node2.id)

    return nothing
end

"""
    _remove_node!(dag::DAG, node::Node; track = true, invalidate_cache = true)

Remove the node from the graph.

## Keyword Arguments
`track::Bool`: Whether to add the changes to the [`DAG`](@ref)'s [`Diff`](@ref). Should be set `false` in parsing or graph creation functions for performance.

`invalidate_cache::Bool`: Whether to invalidate caches associated with the changes. Should also be turned off for graph creation or parsing.

See also: [`_insert_node!`](@ref), [`_insert_edge!`](@ref), [`_remove_edge!`](@ref)
"""
function _remove_node!(dag::DAG, node::Node; track = true, invalidate_cache = true)
    #@info "removing node $(node.id)"

    @assert node.id in keys(dag.nodes) "Trying to remove a node that's not in the graph"

    # 1: mute
    delete!(dag.nodes, node.id)

    # 2: keep track
    if (track)
        push!(dag.diff.removed_nodes, node)
    end

    # 3: invalidate caches
    # nothing to do here, the node has to be kept in dirty nodes to delete operations involving it
    return nothing
end

"""
    _remove_edge!(dag::DAG, node1::Node, node2::Node; track = true, invalidate_cache = true)

Remove the edge between node1 (child) and node2 (parent) into the graph. Returns the integer index of the removed edge.

## Keyword Arguments
- `track::Bool`: Whether to add the changes to the [`DAG`](@ref)'s [`Diff`](@ref). Should be set `false` in parsing or graph creation functions for performance.
- `invalidate_cache::Bool`: Whether to invalidate caches associated with the changes. Should also be turned off for graph creation or parsing.

See also: [`_insert_node!`](@ref), [`_remove_node!`](@ref), [`_insert_edge!`](@ref)
"""
function _remove_edge!(
        dag::DAG, node1::Node, node2::Node; track = true, invalidate_cache = true
    )
    #@info "removing edge $(node1.id) to $(node2.id)"

    # 1: mute
    pre_length1 = length(node1.parents)
    pre_length2 = length(node2.children)

    for i in eachindex(node1.parents)
        if (node1.parents[i] == node2.id)
            splice!(node1.parents, i)
            break
        end
    end

    removed_node_index = 0
    for i in eachindex(node2.children)
        if (node2.children[i][1] == node1.id)
            removed_node_index = node2.children[i][2]
            splice!(node2.children, i)
            break
        end
    end

    #=@assert begin
        removed = pre_length1 - length(node1.parents)
        removed <= 1
    end "removed more than one node from node1's parents"=#

    #=@assert begin
        removed = pre_length2 - length(node2.children)
        removed <= 1
    end "removed more than one node from node2's children"=#

    # 2: keep track
    if (track)
        push!(dag.diff.removed_edges, make_edge(node1, node2, removed_node_index))
    end

    # 3: invalidate caches
    if (!invalidate_cache)
        return removed_node_index
    end

    if (node1 in dag)
        push!(dag.dirty_nodes, node1.id)
    end
    if (node2 in dag)
        push!(dag.dirty_nodes, node2.id)
    end

    return removed_node_index
end

"""
    snapshot_diff(dag::DAG)

Return the graph's [`Diff`](@ref) since last time this function was called. Then, clear the current diff.

See also: [`revert_diff!`](@ref), [`AppliedOperation`](@ref) and [`revert_operation!`](@ref)
"""
function snapshot_diff(dag::DAG)
    t = deepcopy(dag.diff)
    empty!(dag.diff)
    return t
end
