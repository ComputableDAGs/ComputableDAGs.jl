function Base.length(fc::FunctionCall)
    @assert length(fc.value_arguments) == length(fc.arguments) == length(fc.return_symbols) "function call length is undefined, got '$(length(fc.value_arguments))' tuples of value arguments, '$(length(fc.arguments))' tuples of arguments, and '$(length(return_symbols))' return symbols"
    return length(fc.value_arguments)
end

"""
    lower(schedule::Vector{Node}, machine::Machine)

After [`schedule_dag`](@ref) has made a schedule of nodes, this function lowers the vector of [`Node`](@ref)s and [`AbstractDevice`](@ref)s into a vector of [`FunctionCall`](@ref)s.
"""
function lower(schedule::Vector{Tuple{Node, AbstractDevice}}, machine::Machine)
    calls = Vector{FunctionCall}()

    for (node, device) in schedule
        if (node isa DataTaskNode && length(node.children) == 0)
            push!(calls, init_function_call(node, entry_device(machine)))
        else
            push!(calls, function_call(node, device))
        end
    end

    return calls
end
