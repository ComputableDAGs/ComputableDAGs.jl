"""
    nodes(cdag::ComputableDAG)

Return the [`ComputableDAG`](@ref)'s nodes at the current state.
"""
function nodes(cdag::ComputableDAG)
    return cdag.nodes
end

"""
    dependencies(cdag::ComputableDAG, node::Node)

Return the [`Node`](@ref)'s dependencies, i.e., prerequisites for its computation.
"""
function dependencies(cdag::ComputableDAG, node::Node)
    return getindex(Ref(cdag.nodes), getindex.(node.dependencies, 1))
end

"""
    dependents(cdag::ComputableDAG, node::Node)

Return the [`Node`](@ref)'s dependents, i.e., nodes that depend on this node's result.
"""
function dependents(cdag::ComputableDAG, node::Node)
    return getindex(Ref(cdag.nodes), node.dependents)
end

"""
    precedent(cdag::ComputableDAG, node::Node)

Return the [`Node`](@ref)'s precedent, i.e., the node that runs before it on the same device, if any (it could be the first).
"""
function precedent(cdag::ComputableDAG, node::Node)
    return node.precedent
end

"""
    antecedent(cdag::ComputableDAG, node::Node)

Return the [`Node`](@ref)'s antecedent, i.e., the node that runs after it on the same device, if any (it could be the last).
"""
function antecedent(cdag::ComputableDAG, node::Node)
    return node.antecedent
end

# TODO: add partners/siblings back if necessary
# also think of better names for them that don't relate to family
