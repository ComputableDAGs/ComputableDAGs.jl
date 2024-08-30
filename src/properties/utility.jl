"""
    -(prop1::GraphProperties, prop2::GraphProperties)

Subtract `prop1` from `prop2` and return the result as a new [`GraphProperties`](@ref).
Also take care to keep consistent compute intensity.
"""
function -(prop1::GraphProperties, prop2::GraphProperties)
    return (
        data = prop1.data - prop2.data,
        computeEffort = prop1.computeEffort - prop2.computeEffort,
        computeIntensity = if (prop1.data - prop2.data == 0)
            0.0
        else
            (prop1.computeEffort - prop2.computeEffort) / (prop1.data - prop2.data)
        end,
        noNodes = prop1.noNodes - prop2.noNodes,
        noEdges = prop1.noEdges - prop2.noEdges,
    )::GraphProperties
end

"""
    +(prop1::GraphProperties, prop2::GraphProperties)

Add `prop1` and `prop2` and return the result as a new [`GraphProperties`](@ref).
Also take care to keep consistent compute intensity.
"""
function +(prop1::GraphProperties, prop2::GraphProperties)
    return (
        data = prop1.data + prop2.data,
        computeEffort = prop1.computeEffort + prop2.computeEffort,
        computeIntensity = if (prop1.data + prop2.data == 0)
            0.0
        else
            (prop1.computeEffort + prop2.computeEffort) / (prop1.data + prop2.data)
        end,
        noNodes = prop1.noNodes + prop2.noNodes,
        noEdges = prop1.noEdges + prop2.noEdges,
    )::GraphProperties
end

"""
    -(prop::GraphProperties)

Unary negation of the graph properties. `.computeIntensity` will not be negated because `.data` and `.computeEffort` both are.
"""
function -(prop::GraphProperties)
    return (
        data = -prop.data,
        computeEffort = -prop.computeEffort,
        computeIntensity = prop.computeIntensity,   # no negation here!
        noNodes = -prop.noNodes,
        noEdges = -prop.noEdges,
    )::GraphProperties
end
