# for graph mutating functions we need to do a few things
# 1: mute the graph (duh)
# 2: keep track of what was changed for the diff (if track == true)
# 3: invalidate operation caches

"""
    insert_node!(graph::DAG, node::Node)
    insert_node!(graph::DAG, task::AbstractTask, name::String="")

Insert the node into the graph or alternatively construct a node from the given task and insert it.
"""
function insert_node!(graph::DAG, node::Node)
    return _insert_node!(graph, node; track=false, invalidate_cache=false)
end
function insert_node!(graph::DAG, task::AbstractDataTask, name::String="")
    return _insert_node!(graph, make_node(task, name); track=false, invalidate_cache=false)
end
function insert_node!(graph::DAG, task::AbstractComputeTask)
    return _insert_node!(graph, make_node(task); track=false, invalidate_cache=false)
end

"""
    insert_edge!(graph::DAG, node1::Node, node2::Node)

Insert the edge between node1 (child) and node2 (parent) into the graph.
"""
function insert_edge!(graph::DAG, node1::Node, node2::Node, index::Int=0)
    return _insert_edge!(graph, node1, node2, index; track=false, invalidate_cache=false)
end

"""
    _insert_node!(graph::DAG, node::Node; track = true, invalidate_cache = true)

Insert the node into the graph.

!!! warning
    For creating new graphs, use the public version [`insert_node!`](@ref) instead which uses the defaults false for the keywords.

## Keyword Arguments
`track::Bool`: Whether to add the changes to the [`DAG`](@ref)'s [`Diff`](@ref). Should be set `false` in parsing or graph creation functions for performance.

`invalidate_cache::Bool`: Whether to invalidate caches associated with the changes. Should also be turned off for graph creation or parsing.

See also: [`_remove_node!`](@ref), [`_insert_edge!`](@ref), [`_remove_edge!`](@ref)
"""
function _insert_node!(graph::DAG, node::Node; track=true, invalidate_cache=true)
    # 1: mute
    push!(graph.nodes, node)

    # 2: keep track
    if (track)
        push!(graph.diff.addedNodes, node)
    end

    # 3: invalidate caches
    if (!invalidate_cache)
        return node
    end
    push!(graph.dirty_nodes, node)

    return node
end

function _insert_edge!(
    ::DAG, ::DataTaskNode, ::DataTaskNode, ::Int=0; track=true, invalidate_cache=true
)
    throw("trying to create an edge between two data nodes which is not allowed")
end

function _insert_edge!(
    ::DAG, ::ComputeTaskNode, ::ComputeTaskNode, ::Int=0; track=true, invalidate_cache=true
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
    graph::DAG, node1::Node, node2::Node, index::Int=0; track=true, invalidate_cache=true
)
    #@assert (node2 ∉ parents(node1)) && (node1 ∉ children(node2)) "Edge to insert already exists"

    # 1: mute
    # edge points from child to parent
    push!(node1.parents, node2)
    push!(node2.children, (node1, index))

    # 2: keep track
    if (track)
        push!(graph.diff.addedEdges, make_edge(node1, node2, index))
    end

    # 3: invalidate caches
    if (!invalidate_cache)
        return nothing
    end

    invalidate_operation_caches!(graph, node1)
    invalidate_operation_caches!(graph, node2)

    push!(graph.dirty_nodes, node1)
    push!(graph.dirty_nodes, node2)

    return nothing
end

"""
    _remove_node!(graph::DAG, node::Node; track = true, invalidate_cache = true)

Remove the node from the graph.

## Keyword Arguments
`track::Bool`: Whether to add the changes to the [`DAG`](@ref)'s [`Diff`](@ref). Should be set `false` in parsing or graph creation functions for performance.

`invalidate_cache::Bool`: Whether to invalidate caches associated with the changes. Should also be turned off for graph creation or parsing.

See also: [`_insert_node!`](@ref), [`_insert_edge!`](@ref), [`_remove_edge!`](@ref)
"""
function _remove_node!(graph::DAG, node::Node; track=true, invalidate_cache=true)
    #@assert node in graph.nodes "Trying to remove a node that's not in the graph"

    # 1: mute
    delete!(graph.nodes, node)

    # 2: keep track
    if (track)
        push!(graph.diff.removedNodes, node)
    end

    # 3: invalidate caches
    if (!invalidate_cache)
        return nothing
    end

    invalidate_operation_caches!(graph, node)
    delete!(graph.dirty_nodes, node)

    return nothing
end

"""
    _remove_edge!(graph::DAG, node1::Node, node2::Node; track = true, invalidate_cache = true)

Remove the edge between node1 (child) and node2 (parent) into the graph. Returns the integer index of the removed edge.

## Keyword Arguments
- `track::Bool`: Whether to add the changes to the [`DAG`](@ref)'s [`Diff`](@ref). Should be set `false` in parsing or graph creation functions for performance.
- `invalidate_cache::Bool`: Whether to invalidate caches associated with the changes. Should also be turned off for graph creation or parsing.

See also: [`_insert_node!`](@ref), [`_remove_node!`](@ref), [`_insert_edge!`](@ref)
"""
function _remove_edge!(
    graph::DAG, node1::Node, node2::Node; track=true, invalidate_cache=true
)
    # 1: mute
    pre_length1 = length(node1.parents)
    pre_length2 = length(node2.children)

    for i in eachindex(node1.parents)
        if (node1.parents[i] == node2)
            splice!(node1.parents, i)
            break
        end
    end

    removed_node_index = 0
    for i in eachindex(node2.children)
        if (node2.children[i][1] == node1)
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
        removed = pre_length2 - length(children(node2))
        removed <= 1
    end "removed more than one node from node2's children"=#

    # 2: keep track
    if (track)
        push!(graph.diff.removedEdges, make_edge(node1, node2, removed_node_index))
    end

    # 3: invalidate caches
    if (!invalidate_cache)
        return removed_node_index
    end

    invalidate_operation_caches!(graph, node1)
    invalidate_operation_caches!(graph, node2)
    if (node1 in graph)
        push!(graph.dirty_nodes, node1)
    end
    if (node2 in graph)
        push!(graph.dirty_nodes, node2)
    end

    return removed_node_index
end

"""
    get_snapshot_diff(graph::DAG)

Return the graph's [`Diff`](@ref) since last time this function was called.

See also: [`revert_diff!`](@ref), [`AppliedOperation`](@ref) and [`revert_operation!`](@ref)
"""
function get_snapshot_diff(graph::DAG)
    return swapfield!(graph, :diff, Diff())
end

"""
    invalidate_caches!(graph::DAG, operation::NodeReduction)

Invalidate the operation caches for a given [`NodeReduction`](@ref).

This deletes the operation from the graph's possible operations and from the involved nodes' own operation caches.
"""
function invalidate_caches!(graph::DAG, operation::NodeReduction)
    delete!(graph.possible_operations, operation)

    for node in operation.input
        node.nodeReduction = missing
    end

    return nothing
end

"""
    invalidate_caches!(graph::DAG, operation::NodeSplit)

Invalidate the operation caches for a given [`NodeSplit`](@ref).

This deletes the operation from the graph's possible operations and from the involved nodes' own operation caches.
"""
function invalidate_caches!(graph::DAG, operation::NodeSplit)
    delete!(graph.possible_operations, operation)

    # delete the operation from all caches of nodes involved in the operation
    # for node split there is only one node
    operation.input.nodeSplit = missing

    return nothing
end

"""
    invalidate_operation_caches!(graph::DAG, node::ComputeTaskNode)

Invalidate the operation caches of the given node through calls to the respective [`invalidate_caches!`](@ref) functions.
"""
function invalidate_operation_caches!(graph::DAG, node::ComputeTaskNode)
    if !ismissing(node.nodeReduction)
        invalidate_caches!(graph, node.nodeReduction)
    end
    if !ismissing(node.nodeSplit)
        invalidate_caches!(graph, node.nodeSplit)
    end
    return nothing
end

"""
    invalidate_operation_caches!(graph::DAG, node::DataTaskNode)

Invalidate the operation caches of the given node through calls to the respective [`invalidate_caches!`](@ref) functions.
"""
function invalidate_operation_caches!(graph::DAG, node::DataTaskNode)
    if !ismissing(node.nodeReduction)
        invalidate_caches!(graph, node.nodeReduction)
    end
    if !ismissing(node.nodeSplit)
        invalidate_caches!(graph, node.nodeSplit)
    end
    return nothing
end
