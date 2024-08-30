import Base.iterate

const _POSSIBLE_OPERATIONS_FIELDS = fieldnames(PossibleOperations)

_POIteratorStateType =
    NamedTuple{(:result, :state),Tuple{Union{NodeReduction,NodeSplit},Tuple{Symbol,Int64}}}

@inline function iterate(
    possibleOperations::PossibleOperations,
)::Union{Nothing,_POIteratorStateType}
    for fieldname in _POSSIBLE_OPERATIONS_FIELDS
        iterator = iterate(getfield(possibleOperations, fieldname))
        if (!isnothing(iterator))
            return (result = iterator[1], state = (fieldname, iterator[2]))
        end
    end

    return nothing
end

@inline function iterate(
    possibleOperations::PossibleOperations,
    state,
)::Union{Nothing,_POIteratorStateType}
    newStateSym = state[1]
    newStateIt = iterate(getfield(possibleOperations, newStateSym), state[2])
    if !isnothing(newStateIt)
        return (result = newStateIt[1], state = (newStateSym, newStateIt[2]))
    end

    # cycle to next field
    index = findfirst(x -> x == newStateSym, _POSSIBLE_OPERATIONS_FIELDS) + 1

    while index <= length(_POSSIBLE_OPERATIONS_FIELDS)
        newStateSym = _POSSIBLE_OPERATIONS_FIELDS[index]
        newStateIt = iterate(getfield(possibleOperations, newStateSym))
        if !isnothing(newStateIt)
            return (result = newStateIt[1], state = (newStateSym, newStateIt[2]))
        end
        index += 1
    end

    return nothing
end
