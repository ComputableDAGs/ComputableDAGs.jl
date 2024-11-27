"""
    show(io::IO, ops::PossibleOperations)

Print a string representation of the set of possible operations to io.
"""
function Base.show(io::IO, ops::PossibleOperations)
    print(io, length(ops.node_reductions))
    println(io, " Node Reductions: ")
    for nr in ops.node_reductions
        println(io, "  - ", nr)
    end
    print(io, length(ops.node_splits))
    println(io, " Node Splits: ")
    for ns in ops.node_splits
        println(io, "  - ", ns)
    end
end

"""
    show(io::IO, op::NodeReduction)

Print a string representation of the node reduction to io.
"""
function Base.show(io::IO, op::NodeReduction)
    print(io, "NR: ")
    print(io, length(op.input))
    print(io, "x")
    return print(io, task(op.input[1]))
end

"""
    show(io::IO, op::NodeSplit)

Print a string representation of the node split to io.
"""
function Base.show(io::IO, op::NodeSplit)
    print(io, "NS: ")
    return print(io, task(op.input))
end
