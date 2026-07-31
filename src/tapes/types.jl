"""
    Tape{DEV_T}

Lowered representation of a computation, generated from a [`ComputableDAG`](@ref).
"""
struct Tape{DEV_T <: AbstractDevice}
    input_assignment_code::Vector{ExprAssignment}
    schedule::Vector{AbstractInstruction}
    output_symbol::Symbol
    device::DEV_T
end

"""
    TapeRack

A collection of tapes, one tape per device in the target executor. Generated from a [`ComputableDAG`](@ref).
"""
struct TapeRack
    tapes::Dict{AbstractDevice, Tape}
end
