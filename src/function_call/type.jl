"""
    FunctionCall{VAL_T<:Tuple,FUNC_T<:Union{Function,Expr}}

Representation of a function call. Contains the function to call (or an expression of a value to assign),
value arguments of type `VAL_T`, argument symbols, the return symbol(s) and type(s) and the device to execute on.



A function call encapsulates the total of the expected functionality of a node in the CDAG when it is executed. This means that it
- acquires its inputs, potentially from other devices, but not duplicating data transfers,
- computes its node's compute function on all its inputs and produces the outputs, and
- sends the outputs to any devices that will need it, once.



"""
struct FunctionCall{VAL_T <: Tuple, FUNC_T <: Union{Function, Expr}}
    # the function or expression representing the computation
    func::FUNC_T

    # tuple of value arguments for the function call, will be prepended to the other arguments
    value_arguments::Vector{VAL_T}

    # symbols of the inputs to the function call
    arguments::Vector{Vector{Symbol}}

    # the return symbols
    return_symbols::Vector{Vector{Symbol}}

    device::AbstractDevice
end
function FunctionCall(
        func::Union{Function, Expr},
        value_arguments::VAL_T,
        arguments::Vector{Symbol},
        return_symbol::Vector{Symbol},
        device::AbstractDevice,
    ) where {VAL_T <: Tuple}
    # convenience constructor for function calls that do not use vectorization, which is most of the use cases
    @assert func isa Function || length(value_arguments) == 0 "no value arguments are allowed for a an Expr FunctionCall, but got '$value_arguments'"
    return FunctionCall(
        func, [value_arguments], [arguments], [return_symbol], device
    )
end
