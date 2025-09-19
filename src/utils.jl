"""
    noop()

Function with no arguments, returns nothing, does nothing. Useful for noop [`FunctionCall`](@ref)s.
"""
@inline noop() = nothing

"""
    bytes_to_human_readable(bytes)

Return a human readable string representation of the given number.

```jldoctest
julia> using ComputableDAGs

julia> ComputableDAGs.bytes_to_human_readable(4096)
"4.0 KiB"
```
"""
function bytes_to_human_readable(bytes)
    units = ["B", "KiB", "MiB", "GiB", "TiB"]
    unit_index = 1
    while bytes >= 1024 && unit_index < length(units)
        bytes /= 1024
        unit_index += 1
    end
    return string(round(bytes; sigdigits = 4), " ", units[unit_index])
end

"""
    _lt_nodes(n1::Node, n2::Node)

Less-Than comparison between nodes. Uses the nodes' ids to sort.
"""
function _lt_nodes(n1::Node, n2::Node)
    return n1.id < n2.id
end

"""
    _lt_node_tuples(n1::Tuple{Node, Int}, n2::Tuple{Node, Int})

Less-Than comparison between nodes with indices.
"""
function _lt_node_tuples(n1::Tuple{Node, Int}, n2::Tuple{Node, Int})
    if n1[2] == n2[2]
        return n1[1].id < n2[1].id
    else
        return n1[2] < n2[2]
    end
end

"""
    sort_node!(node::Node)

Sort the nodes' parents and children vectors. The vectors are mostly very short so sorting does not take a lot of time.
Sorted nodes are required to make the finding of [`NodeReduction`](@ref)s a lot faster using the [`NodeTrie`](@ref) data structure.
"""
function sort_node!(node::Node)
    sort!(children(node); lt = _lt_node_tuples)
    return sort!(parents(node); lt = _lt_nodes)
end

"""
    mem(graph::DAG)

Return the memory footprint of the graph in Byte. Should be the same result as `Base.summarysize(graph)` but a lot faster.
"""
function mem(graph::DAG)
    size = 0
    size += Base.summarysize(graph.nodes; exclude = Union{Node})
    for n in graph.nodes
        size += mem(n)
    end

    size += sizeof(graph.applied_operations)
    size += sizeof(graph.operations_to_apply)

    size += sizeof(graph.possible_operations)
    for op in graph.possible_operations.node_reductions
        size += mem(op)
    end
    for op in graph.possible_operations.node_splits
        size += mem(op)
    end

    size += Base.summarysize(graph.dirty_nodes; exclude = Union{Node})
    return size += sizeof(diff)
end

"""
    mem(op::Operation)

Return the memory footprint of the operation in Byte. Used in [`mem(graph::DAG)`](@ref). Unlike `Base.summarysize()` this doesn't follow all references which would yield (almost) the size of the entire graph.
"""
function mem(op::Operation)
    return Base.summarysize(op; exclude = Union{Node})
end

"""
    mem(op::Operation)

Return the memory footprint of the node in Byte. Used in [`mem(graph::DAG)`](@ref). Unlike `Base.summarysize()` this doesn't follow all references which would yield (almost) the size of the entire graph.
"""
function mem(node::Node)
    return Base.summarysize(node; exclude = Union{Node, Operation})
end

"""
    unroll_symbol_vector(vec::Vector{Symbol})

Return the given vector as single String without quotation marks or brackets.
"""
function unroll_symbol_vector(vec::VEC) where {VEC <: Union{AbstractVector, Tuple}}
    return Expr(:tuple, vec...)
end

@inline function _call(f, args::Vararg)
    return f(args...)
end
