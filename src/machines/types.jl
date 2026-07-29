"""
    Machine

A machine represents the entire device architecture that a
[`ComputableDAG`](@ref) can be executed on.
"""
struct Machine
    devices::Dict{UUID, AbstractDevice}
end
