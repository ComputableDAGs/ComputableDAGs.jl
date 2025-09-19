"""
    -(prop1::GraphProperties, prop2::GraphProperties)

Subtract `prop1` from `prop2` and return the result as a new [`GraphProperties`](@ref).
Also take care to keep consistent compute intensity.
"""
function Base.:-(prop1::GraphProperties, prop2::GraphProperties)
    return (
        data = prop1.data - prop2.data,
        compute_effort = prop1.compute_effort - prop2.compute_effort,
        compute_intensity = if (prop1.data - prop2.data == 0)
            0.0
        else
            (prop1.compute_effort - prop2.compute_effort) / (prop1.data - prop2.data)
        end,
        number_of_nodes = prop1.number_of_nodes - prop2.number_of_nodes,
        number_of_edges = prop1.number_of_edges - prop2.number_of_edges,
    )::GraphProperties
end

"""
    +(prop1::GraphProperties, prop2::GraphProperties)

Add `prop1` and `prop2` and return the result as a new [`GraphProperties`](@ref).
Also take care to keep consistent compute intensity.
"""
function Base.:+(prop1::GraphProperties, prop2::GraphProperties)
    return (
        data = prop1.data + prop2.data,
        compute_effort = prop1.compute_effort + prop2.compute_effort,
        compute_intensity = if (prop1.data + prop2.data == 0)
            0.0
        else
            (prop1.compute_effort + prop2.compute_effort) / (prop1.data + prop2.data)
        end,
        number_of_nodes = prop1.number_of_nodes + prop2.number_of_nodes,
        number_of_edges = prop1.number_of_edges + prop2.number_of_edges,
    )::GraphProperties
end

"""
    -(prop::GraphProperties)

Unary negation of the graph properties. `.compute_intensity` will not be negated because `.data` and `.compute_effort` both are.
"""
function Base.:-(prop::GraphProperties)
    return (
        data = -prop.data,
        compute_effort = -prop.compute_effort,
        compute_intensity = prop.compute_intensity,   # no negation here!
        number_of_nodes = -prop.number_of_nodes,
        number_of_edges = -prop.number_of_edges,
    )::GraphProperties
end
