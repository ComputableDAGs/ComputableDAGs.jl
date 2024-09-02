"""
    isempty(operations::PossibleOperations)

Return whether `operations` is empty, i.e. all of its fields are empty.
"""
function isempty(operations::PossibleOperations)
    return isempty(operations.nodeReductions) && isempty(operations.nodeSplits)
end

"""
    length(operations::PossibleOperations)

Return a named tuple with the number of each of the operation types as a named tuple. The fields are named the same as the [`PossibleOperations`](@ref)'.
"""
function length(operations::PossibleOperations)
    return (
        nodeReductions=length(operations.nodeReductions),
        nodeSplits=length(operations.nodeSplits),
    )
end

"""
    delete!(operations::PossibleOperations, op::NodeReduction)

Delete the given node reduction from the possible operations.
"""
function delete!(operations::PossibleOperations, op::NodeReduction)
    delete!(operations.nodeReductions, op)
    return operations
end

"""
    delete!(operations::PossibleOperations, op::NodeSplit)

Delete the given node split from the possible operations.
"""
function delete!(operations::PossibleOperations, op::NodeSplit)
    delete!(operations.nodeSplits, op)
    return operations
end

"""
    can_reduce(n1::Node, n2::Node)

Return whether the given two nodes can be reduced. See [`NodeReduction`](@ref) for the requirements.
"""
function can_reduce(n1::Node, n2::Node)
    return false
end

function can_reduce(
    n1::NodeType, n2::NodeType
) where {
    TaskType<:AbstractTask,NodeType<:Union{DataTaskNode{TaskType},ComputeTaskNode{TaskType}}
}
    n1_length = length(children(n1))
    n2_length = length(children(n2))

    if (n1_length != n2_length)
        return false
    end

    # this seems to be the most common case so do this first
    # doing it manually is a lot faster than using the sets for a general solution
    if (n1_length == 2)
        if (children(n1)[1] != children(n2)[1])
            if (children(n1)[1] != children(n2)[2])
                return false
            end
            # 1_1 == 2_2
            if (children(n1)[2] != children(n2)[1])
                return false
            end
            return true
        end

        # 1_1 == 2_1
        if (children(n1)[2] != children(n2)[2])
            return false
        end
        return true
    end

    # this is simple
    if (n1_length == 1)
        return children(n1)[1] == children(n2)[1]
    end

    # this takes a long time
    return Set(children(n1)) == Set(children(n2))
end

"""
    can_split(n1::Node)

Return whether the given node can be split. See [`NodeSplit`](@ref) for the requirements.
"""
function can_split(n::Node)
    return length(parents(n)) > 1
end

"""
    ==(op1::Operation, op2::Operation)

Fallback implementation of operation equality. Return false. Actual comparisons are done by the overloads of same type operation comparisons.
"""
function ==(op1::Operation, op2::Operation)
    return false
end

"""
    ==(op1::NodeReduction, op2::NodeReduction)

Equality comparison between two node reductions. Two node reductions are considered equal when they have the same inputs.
"""
function ==(op1::NodeReduction, op2::NodeReduction)
    # node reductions are equal exactly if their first input is the same
    return op1.input[1].id == op2.input[1].id
end

"""
    ==(op1::NodeSplit, op2::NodeSplit)

Equality comparison between two node splits. Two node splits are considered equal if they have the same input node.
"""
function ==(op1::NodeSplit, op2::NodeSplit)
    return op1.input == op2.input
end
