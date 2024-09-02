# functions to throw assertion errors for inconsistent or wrong node operations
# should be called with @assert
# the functions throw their own errors though, to still have helpful error messages

"""
    is_valid_node_reduction_input(graph::DAG, nodes::Vector{Node})

Assert for a gven node reduction input whether the nodes can be reduced. For the requirements of a node reduction see [`NodeReduction`](@ref).

Intended for use with `@assert` or `@test`.
"""
function is_valid_node_reduction_input(graph::DAG, nodes::Vector{Node})
    for n in nodes
        if n ∉ graph
            throw(
                AssertionError(
                    "[Node Reduction] The given nodes are not part of the given graph"
                ),
            )
        end
        @assert is_valid(graph, n)
    end

    t = typeof(task(nodes[1]))
    for n in nodes
        if typeof(task(n)) != t
            throw(
                AssertionError("[Node Reduction] The given nodes are not of the same type")
            )
        end

        if (typeof(n) <: DataTaskNode)
            if (n.name != nodes[1].name)
                throw(
                    AssertionError(
                        "[Node Reduction] The given nodes do not have the same name"
                    ),
                )
            end
        end
    end

    n1_children = nodes[1].children
    for n in nodes
        if Set(n1_children) != Set(n.children)
            throw(
                AssertionError(
                    "[Node Reduction] The given nodes do not have equal prerequisite nodes which is required for node reduction",
                ),
            )
        end
    end

    return true
end

"""
    is_valid_node_split_input(graph::DAG, n1::Node)

Assert for a gven node split input whether the node can be split. For the requirements of a node split see [`NodeSplit`](@ref).

Intended for use with `@assert` or `@test`.
"""
function is_valid_node_split_input(graph::DAG, n1::Node)
    if n1 ∉ graph
        throw(AssertionError("[Node Split] The given node is not part of the given graph"))
    end

    if length(n1.parents) <= 1
        throw(
            AssertionError(
                "[Node Split] The given node does not have multiple parents which is required for node split",
            ),
        )
    end

    @assert is_valid(graph, n1)

    return true
end

"""
    is_valid(graph::DAG, nr::NodeReduction)

Assert for a given [`NodeReduction`](@ref) whether it is a valid operation in the graph.

Intended for use with `@assert` or `@test`.
"""
function is_valid(graph::DAG, nr::NodeReduction)
    @assert is_valid_node_reduction_input(graph, nr.input)
    #@assert nr in graph.possibleOperations.nodeReductions "NodeReduction is not part of the graph's possible operations!"
    return true
end

"""
    is_valid(graph::DAG, nr::NodeSplit)

Assert for a given [`NodeSplit`](@ref) whether it is a valid operation in the graph.

Intended for use with `@assert` or `@test`.
"""
function is_valid(graph::DAG, ns::NodeSplit)
    @assert is_valid_node_split_input(graph, ns.input)
    #@assert ns in graph.possibleOperations.nodeSplits "NodeSplit is not part of the graph's possible operations!"
    return true
end
