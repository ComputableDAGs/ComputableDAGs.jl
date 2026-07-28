"""
    AbstractInstruction

Base type for the different types of instructions representable in CDAGs.
"""
abstract type AbstractInstruction end

"""
    FunctionCall{VAL_T<:Tuple}

Representation of a function call. Contains the function to call, value
arguments of type `VAL_T`, argument symbols, the return symbol and type,
and the device to execute on.
"""
struct FunctionCall{VAL_T <: Tuple}
    # the function representing the computation
    func::Function

    # tuple of value arguments for the function call, will be prepended to the other arguments
    value_arguments::VAL_T

    # symbols of the inputs to the function call
    arguments::Vector{Symbol}

    # the return symbols
    return_symbols::Vector{Symbol}
end

"""
    Assignment

An assignment instruction which sets the given `return_symbol` to the value of
the expression given. This is used for the entry points of the CDAG to grab
the relevant part of the CDAGs input.
"""
struct Assignment
    expr::Expr

    return_symbol::Symbol
end

"""
    SendInstruction

A send instruction that sends the value identified by the given `symbol` to
the given destination device. This is collaborative, so the destination device
must have a corresponding [`RecvInstruction`](@ref).
"""
struct SendInstruction
    #dest::Device

    symbol::Symbol
end

"""
    RecvInstruction

A receive instruction that receives the value identified by the given `symbol`
from the given device and stores it in that symbol. This is collaborative, so
the origin device must have a corresponding [`SendInstruction`](@ref).
"""
struct RecvInstruction
    #origin::Device

    symbol::Symbol
end

"""
    VectorizedCall

A vectorized version of the [`FunctionCall`](@ref). It behaves in the same way,
but allows parallelism of the device it's running on to be used to process
multiple instructions simultaneously.

!!! warn
    To be implemented.
"""
struct VectorizedCall
    # TBW
end

"""
    Accumulation

An accumulation represents an operation on many inputs with a commutative
operator and a neutral element. It behaves like the `Base.accumulate` call but
allows the individual operations to be scheduled independently, allowing more
freedom in the schedule and lower cache requirement.

!!! warn
    To be implemented.
"""
struct Accumulation
    neutral
    op
    arguments
    return_symbol
    # TBW
end
