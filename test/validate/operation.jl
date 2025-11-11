function is_valid_node_reduction_input(dag::DAG, nodes::Vector{NodeType}) where {NodeType <: Node}
    for n in nodes
        if n ∉ dag
            throw(
                AssertionError(
                    "[Node Reduction] the given nodes are not part of the given graph"
                ),
            )
        end
        @assert is_valid(dag, n)
    end

    t = typeof(task(nodes[1]))
    for n in nodes
        if typeof(task(n)) != t
            throw(
                AssertionError("[Node Reduction] the given nodes are not of the same type")
            )
        end

        if (typeof(n) <: DataTaskNode)
            if (n.name != nodes[1].name)
                throw(
                    AssertionError(
                        "[Node Reduction] the given nodes do not have the same name"
                    ),
                )
            end
        end
    end

    n1_children = ComputableDAGs.children(dag, nodes[1])
    for n in nodes
        if Set(n1_children) != Set(ComputableDAGs.children(dag, n))
            throw(
                AssertionError(
                    "[Node Reduction] the given nodes do not have equal prerequisite nodes which is required for node reduction",
                ),
            )
        end
    end

    return true
end

function is_valid_node_split_input(dag::DAG, n1::Node)
    if n1 ∉ dag
        throw(AssertionError("[Node Split] the given node is not part of the given graph"))
    end

    if length(n1.parents) <= 1
        throw(
            AssertionError(
                "[Node Split] the given node does not have multiple parents which is required for node split",
            ),
        )
    end

    @assert is_valid(dag, n1)

    return true
end

function is_valid(dag::DAG, nr::ComputableDAGs.NodeReduction)
    @assert is_valid_node_reduction_input(dag, getindex.(Ref(dag.nodes), nr.input))
    return true
end

function is_valid(dag::DAG, ns::ComputableDAGs.NodeSplit)
    @assert is_valid_node_split_input(dag, dag.nodes[ns.input])
    return true
end
