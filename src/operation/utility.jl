"""
    isempty(operations::PossibleOperations)

Return whether `operations` is empty, i.e. all of its fields are empty.
"""
function Base.isempty(operations::PossibleOperations)
    return isempty(operations.node_reductions) && isempty(operations.node_splits)
end

"""
    length(operations::PossibleOperations)

Return a named tuple with the number of each of the operation types as a named tuple. The fields are named the same as the [`PossibleOperations`](@ref)'.
"""
function Base.length(operations::PossibleOperations)
    return (
        node_reductions = length(operations.node_reductions),
        node_splits = length(operations.node_splits),
    )
end

"""
    delete!(operations::PossibleOperations, op::NodeReduction)

Delete the given node reduction from the possible operations.
"""
function Base.delete!(operations::PossibleOperations, op::NodeReduction)
    delete!(operations.node_reductions, op)
    return operations
end

"""
    delete!(operations::PossibleOperations, op::NodeSplit)

Delete the given node split from the possible operations.
"""
function Base.delete!(operations::PossibleOperations, op::NodeSplit)
    delete!(operations.node_splits, op)
    return operations
end

"""
    can_reduce(n1::Node, n2::Node)

Return whether the given two nodes can be reduced. See [`NodeReduction`](@ref) for the requirements.
"""
function can_reduce(::Node, ::Node)
    return false
end

function can_reduce(
        n1::NodeType, n2::NodeType
    ) where {
        TaskType <: AbstractTask, NodeType <: Union{DataTaskNode{TaskType}, ComputeTaskNode{TaskType}},
    }
    n1_length = length(n1.children)
    n2_length = length(n2.children)

    if (n1_length != n2_length)
        return false
    end

    # this seems to be the most common case so do this first
    # doing it manually is a lot faster than using the sets for a general solution
    if (n1_length == 2)
        if (n1.children[1] != n2.children[1])
            if (n1.children[1] != n2.children[2])
                return false
            end
            # 1_1 == 2_2
            if (n1.children[2] != n2.children[1])
                return false
            end
            return true
        end

        # 1_1 == 2_1
        if (n1.children[2] != n2.children[2])
            return false
        end
        return true
    end

    # this is simple
    if (n1_length == 1)
        return n1.children[1] == n2.children[1]
    end

    # this takes a long time
    return Set(n1.children) == Set(n2.children)
end

"""
    can_split(n1::Node)

Return whether the given node can be split. See [`NodeSplit`](@ref) for the requirements.
"""
function can_split(n::Node)
    return length(n.parents) > 1
end

"""
    ==(op1::Operation, op2::Operation)

Fallback implementation of operation equality. Return false. Actual comparisons are done by the overloads of same type operation comparisons.
"""
function Base.:(==)(op1::Operation, op2::Operation)
    return false
end

"""
    ==(op1::NodeReduction, op2::NodeReduction)

Equality comparison between two node reductions. Two node reductions are considered equal when they have the same inputs.
"""
function Base.:(==)(op1::NodeReduction, op2::NodeReduction)
    # node reductions are equal exactly if their first input is the same
    return op1.input[1] == op2.input[1]
end

"""
    ==(op1::NodeSplit, op2::NodeSplit)

Equality comparison between two node splits. Two node splits are considered equal if they have the same input node.
"""
function Base.:(==)(op1::NodeSplit, op2::NodeSplit)
    return op1.input == op2.input
end
