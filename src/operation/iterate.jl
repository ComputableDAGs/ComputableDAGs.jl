const _POSSIBLE_OPERATIONS_FIELDS = fieldnames(PossibleOperations)

_POIteratorStateType = NamedTuple{
    (:result, :state), Tuple{Union{NodeReduction, NodeSplit}, Tuple{Symbol, Int64}},
}

@inline function Base.iterate(
        possible_operations::PossibleOperations
    )::Union{Nothing, _POIteratorStateType}
    for fieldname in _POSSIBLE_OPERATIONS_FIELDS
        iterator = iterate(getfield(possible_operations, fieldname))
        if (!isnothing(iterator))
            return (result = iterator[1], state = (fieldname, iterator[2]))
        end
    end

    return nothing
end

@inline function Base.iterate(
        possible_operations::PossibleOperations, state
    )::Union{Nothing, _POIteratorStateType}
    new_state_sym = state[1]
    new_state_it = iterate(getfield(possible_operations, new_state_sym), state[2])
    if !isnothing(new_state_it)
        return (result = new_state_it[1], state = (new_state_sym, new_state_it[2]))
    end

    # cycle to next field
    index = findfirst(x -> x == new_state_sym, _POSSIBLE_OPERATIONS_FIELDS) + 1

    while index <= length(_POSSIBLE_OPERATIONS_FIELDS)
        new_state_sym = _POSSIBLE_OPERATIONS_FIELDS[index]
        new_state_it = iterate(getfield(possible_operations, new_state_sym))
        if !isnothing(new_state_it)
            return (result = new_state_it[1], state = (new_state_sym, new_state_it[2]))
        end
        index += 1
    end

    return nothing
end
