"""
    AbstractInstruction

Base type for the different types of instructions representable in CDAGs.
"""
abstract type AbstractInstruction end

"""
    AbstractCommunicationInstruction <: AbstractInstruction

Base type for communication instructions, such as [`RecvInstruction`](@ref).
"""
abstract type AbstractCommunicationInstruction <: AbstractInstruction end

"""
    AbstractComputeInstruction <: AbstractInstruction

Base type for compute instructions, such as [`FunctionCall`](@ref).
"""
abstract type AbstractComputeInstruction <: AbstractInstruction end

"""
    FunctionCall{VAL_T<:Tuple} <: AbstractComputeInstruction

Representation of a function call. Contains the function to call, value
arguments of type `VAL_T`, argument symbols, the return symbol and type,
and the device to execute on.
"""
struct FunctionCall{VAL_T <: Tuple} <: AbstractComputeInstruction
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
    ExprAssignment <: AbstractComputeInstruction

An assignment instruction which sets the given `return_symbol` to the value of
the expression given. This is used for the entry points of the CDAG to grab
the relevant part of the CDAGs input.
"""
struct ExprAssignment <: AbstractComputeInstruction
    expr::Expr

    return_symbol::Symbol
end

"""
    SendInstruction <: AbstractCommunicationInstruction

A send instruction that sends the value identified by the given `id` to
the given destination device. This is collaborative, so the destination device
must have a corresponding [`RecvInstruction`](@ref).
"""
struct SendInstruction <: AbstractCommunicationInstruction
    dest::AbstractDevice

    on_machine::Bool

    id::UUID
end

"""
    RecvInstruction{T} <: AbstractCommunicationInstruction

A receive instruction that receives the value identified by the given `id`
from the given device and stores it in that symbol. This is collaborative, so
the origin device must have a corresponding [`SendInstruction`](@ref).

`T` is the type of the expected value to receive.
"""
struct RecvInstruction{T} <: AbstractCommunicationInstruction
    origin::AbstractDevice

    on_machine::Bool

    id::UUID

    type::Type{T}
end

"""
    VectorizedCall <: AbstractComputeInstruction

A vectorized version of the [`FunctionCall`](@ref). It behaves in the same way,
but allows parallelism of the device it's running on to be used to process
multiple instructions simultaneously.

!!! warn
    To be implemented.
"""
struct VectorizedCall <: AbstractComputeInstruction
    # TBW
end

"""
    Accumulation <: AbstractComputeInstruction

An accumulation represents an operation on many inputs with a commutative
operator and a neutral element. It behaves like the `Base.accumulate` call but
allows the individual operations to be scheduled independently, allowing more
freedom in the schedule and lower cache requirement.

!!! warn
    To be implemented.
"""
struct Accumulation <: AbstractComputeInstruction
    neutral
    op
    arguments
    return_symbol
    # TBW
    # TODO: i think this is nonsense and not needed as an instruction, only as a node type
end
