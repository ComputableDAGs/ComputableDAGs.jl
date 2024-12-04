"""
    NodeIdTrie

Helper struct for [`NodeTrie`](@ref). After the Trie's first level, every Trie level contains the vector of nodes that had children up to that level, and the TrieNode's children by UUID of the node's children.
"""
mutable struct NodeIdTrie{NodeType<:Node}
    value::Vector{NodeType}
    children::Dict{UUID,NodeIdTrie{NodeType}}
end

"""
    NodeTrie

Trie data structure for node reduction, inserts nodes by children.
Assumes that given nodes have ordered vectors of children (see [`sort_node!`](@ref)).
First insertion level is the node's own task type and thus does not have a value (every node has a task type).

See also: [`insert!`](@ref) and [`collect`](@ref)
"""
mutable struct NodeTrie
    children::Dict{DataType,NodeIdTrie}
end

"""
    NodeTrie()

Constructor for an empty [`NodeTrie`](@ref).
"""
function NodeTrie()
    return NodeTrie(Dict{DataType,NodeIdTrie}())
end

"""
    NodeIdTrie()

Constructor for an empty [`NodeIdTrie`](@ref).
"""
function NodeIdTrie{NodeType}() where {NodeType<:Node}
    return NodeIdTrie(Vector{NodeType}(), Dict{UUID,NodeIdTrie{NodeType}}())
end

"""
    insert_helper!(trie::NodeIdTrie, node::Node, depth::Int)

Insert the given node into the trie. The depth is used to iterate through the trie layers, while the function calls itself recursively until it ran through all children of the node.
"""
function insert_helper!(
    trie::NodeIdTrie{NodeType}, node::NodeType, depth::Int
) where {NodeType<:Node}
    if (length(children(node)) == depth)
        push!(trie.value, node)
        return nothing
    end

    depth = depth + 1
    id = node.children[depth][1].id

    if (!haskey(trie.children, id))
        trie.children[id] = NodeIdTrie{NodeType}()
    end
    return insert_helper!(trie.children[id], node, depth)
end

"""
    insert!(trie::NodeTrie, node::Node)

Insert the given node into the trie. It's sorted by its type in the first layer, then by its children in the following layers.
"""
function Base.insert!(trie::NodeTrie, node::NodeType) where {NodeType<:Node}
    if (!haskey(trie.children, NodeType))
        trie.children[NodeType] = NodeIdTrie{NodeType}()
    end
    return insert_helper!(trie.children[NodeType], node, 0)
end

"""
    collect_helper(trie::NodeIdTrie, acc::Set{Vector{Node}})

Collects the Vectors of this [`NodeIdTrie`](@ref) node and all its children and puts them in the `acc` argument.
"""
function collect_helper(trie::NodeIdTrie, acc::Set{Vector{Node}})
    if (length(trie.value) >= 2)
        push!(acc, trie.value)
    end

    for (id, child) in trie.children
        collect_helper(child, acc)
    end
    return nothing
end

"""
    collect(trie::NodeTrie)

Return all sets of at least 2 [`Node`](@ref)s that have accumulated in leaves of the trie.
"""
function Base.collect(trie::NodeTrie)
    acc = Set{Vector{Node}}()
    for (t, child) in trie.children
        collect_helper(child, acc)
    end
    return acc
end
