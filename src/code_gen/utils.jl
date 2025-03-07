function Base.length(fc::FunctionCall)
    @assert length(fc.value_arguments) == length(fc.arguments) == length(fc.return_symbols) "function call length is undefined, got '$(length(fc.value_arguments))' tuples of value arguments, '$(length(fc.arguments))' tuples of arguments, and '$(length(return_symbols))' return symbols"
    return length(fc.value_arguments)
end

"""
    infer_types!(tape::Tape, context_module::Module)

Infer the result type of each function call in the given tape. Returns a dictionary with the result type for each symbol and sets each function call's return_types.
This function assumes that each [`FunctionCall`](@ref) has only one statically inferrable return type and will throw an exception otherwise.
"""
function infer_types!(tape::Tape, context_module::Module; concrete_input_type::Type=Nothing)
    known_result_types = Dict{Symbol,Type}()

    if concrete_input_type == Nothing   # the type, not the value "nothing"
        # the only initially known type
        known_result_types[:input] = input_type(tape.instance)
    else
        @debug "using given concrete input type $(concrete_input_type)"
        known_result_types[:input] = concrete_input_type
    end

    for fc in tape.input_assign_code
        res_types = result_types(fc, known_result_types, context_module)
        fc.return_types = res_types
        for (s, t) in Iterators.zip(
            Iterators.flatten(fc.return_symbols),
            Iterators.cycle(res_types, length(fc.return_symbols)),
        )
            known_result_types[s] = t
        end
    end

    for fc in tape.schedule
        res_types = result_types(fc, known_result_types, context_module)
        fc.return_types = res_types
        for (s, t) in Iterators.zip(
            Iterators.flatten(fc.return_symbols),
            Iterators.cycle(res_types, length(fc.return_symbols)),
        )
            known_result_types[s] = t
        end
    end

    if any(
        x -> x == Any,
        getindex.(
            Ref(known_result_types), Iterators.flatten(last(tape.schedule).return_symbols)
        ),
    )
        @warn "the inferred return type of the function is 'Any', which will likely lead to problems\ntry to \n\t 1: provide a more specific function argument type in your 'input_type' (got: $(input_type(tape.instance)))\n\t 2: increase your compute functions' type stability" *
            (
            if concrete_input_type == Nothing
                "\n\t 3: try passing a 'concrete_input_type' as a keyword argument to the function generation"
            else
                ""
            end
        )
    end

    return known_result_types
end

"""
    lower(schedule::Vector{Node}, machine::Machine)

After [`schedule_dag`](@ref) has made a schedule of nodes, this function lowers the vector of [`Node`](@ref)s into a vector of [`FunctionCall`](@ref)s.
"""
function lower(schedule::Vector{Node}, machine::Machine)
    calls = Vector{FunctionCall}()

    for node in schedule
        if (node isa DataTaskNode && length(children(node)) == 0)
            push!(calls, get_init_function_call(node, entry_device(machine)))
        else
            push!(calls, get_function_call(node))
        end
    end

    return calls
end
