"""
    ==(e1::Edge, e2::Edge)

Equality comparison between two edges.
"""
function ==(e1::Edge, e2::Edge)
    return e1.edge[1] == e2.edge[1] && e1.edge[2] == e2.edge[2]
end

"""
    ==(n1::Node, n2::Node)

Fallback equality comparison between two nodes. For equal node types, the more specific versions of this function will be called.
"""
function ==(n1::Node, n2::Node)
    return false
end

"""
    ==(n1::ComputeTaskNode, n2::ComputeTaskNode)

Equality comparison between two [`ComputeTaskNode`](@ref)s.
"""
function ==(
    n1::ComputeTaskNode{TaskType},
    n2::ComputeTaskNode{TaskType},
) where {TaskType<:AbstractComputeTask}
    return n1.id == n2.id
end

"""
    ==(n1::DataTaskNode, n2::DataTaskNode)

Equality comparison between two [`DataTaskNode`](@ref)s.
"""
function ==(
    n1::DataTaskNode{TaskType},
    n2::DataTaskNode{TaskType},
) where {TaskType<:AbstractDataTask}
    return n1.id == n2.id
end
