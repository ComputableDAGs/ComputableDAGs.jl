"""
    FunctionCall{VAL_T<:Tuple,FUNC_T<:Union{Function,Expr}}

Representation of a function call. Contains the function to call (or an expression of a value to assign),
value arguments of type `VAL_T`, argument symbols, the return symbol(s) and type(s) and the device to execute on.

To support vectorization, i.e., calling the same function on multiple inputs (SIMD), the value arguments, arguments,
and return symbols are each vectors of the actual inputs. In the non-vectorized case, these `Vector`s simply always
have length 1. For this common case, a special constructor exists which automatically wraps each of these arguments
in a `Vector`.

## Type Arguments
- `VAL_T<:Tuple`: A tuple of all the value arguments that are passed to the function when it's called.
- `FUNC_T<:Union{Function, Expr}`: The type of the function. `Function` is the default, but in some cases, an `Expr`
    of a value can be necessary to assign to the return symbol. In this case, no arguments are allowed.

## Fields
- `func::FUNC_T`: The function to be called, or an expression containing a value to assign to the return_symbol.
- `value_arguments::Vector{VAL_T}`: The value arguments for the function call. These are passed *first* to the
    function, in the order given here. The `Vector` contains the tuple of value arguments for each vectorization
    member.
- `arguments::Vector{Vector{Symbol}}`: The first vector represents the vectorization, the second layer represents the
    symbols that will be passed as arguments to the function call.
- `return_symbols::Vector{Vector{Symbol}}`: As with the arguments, the first vector level represents the vectorization,
    the second represents the symbols that the results of the function call are assigned to. For most function calls,
    there is only one return symbol. When using closures when generating a function body for a [`Tape`](@ref), the
    option to have multiple return symbols is necessary.
- `return_types::Vector{<:Type}`: The types of the function call with the arguments provided. This field only contains
    one level of Vector, because it is required that a `FunctionCall` is type stable, and therefore, the types of the
    return symbols have to be equal for all members of a vectorization. The return type is initially set to `Nothing`
    and later inferred and assigned by [`infer_types!`](@ref).
- `device::AbstractDevice`: The device that this function call is scheduled on.
"""
mutable struct FunctionCall{VAL_T<:Tuple,FUNC_T<:Union{Function,Expr}}
    func::FUNC_T
    value_arguments::Vector{VAL_T}          # tuple of value arguments for the function call, will be prepended to the other arguments
    arguments::Vector{Vector{Symbol}}       # symbols of the inputs to the function call
    return_symbols::Vector{Vector{Symbol}}  # the return symbols
    return_types::Vector{<:Type}            # the return type of the function call(s); there can only be one return type since we require type stability
    device::AbstractDevice
end
function FunctionCall(
    func::Union{Function,Expr},
    value_arguments::VAL_T,
    arguments::Vector{Symbol},
    return_symbol::Vector{Symbol},
    return_types::Vector{<:Type},
    device::AbstractDevice,
) where {VAL_T<:Tuple}
    # convenience constructor for function calls that do not use vectorization, which is most of the use cases
    @assert length(return_types) == 0 || length(return_types) == length(return_symbol) "number of return types '$(length(return_types))' does not match the number of return symbols '$(length(return_symbol))'"
    @assert func isa Function || length(value_arguments) == 0 "no value arguments are allowed for a an Expr FunctionCall, but got '$value_arguments'"
    return FunctionCall(
        func, [value_arguments], [arguments], [return_symbol], return_types, device
    )
end

"""
    Tape{INPUT}

Lowered representation of a computation, generated from a [`DAG`](@ref) through [`gen_tape`](@ref).

- `INPUT` the input type of the problem instance, see also the interface function [`input_type`](@ref)

## Fields
- `input_assign_code::Vector{FunctionCall}`: The [`FunctionCall`](@ref)s representing the input assignments,
    mapping part of the input of the computation to each DAG entry node. These functions are generated using
    the interface function [`input_expr`](@ref).
- `schedule::Vector{FunctionCall}`: The [`FunctionCall`](@ref)s representing the function body of the computation.
    There is one function call for each node in the [`DAG`](@ref).
- `output_symbol::Symbol`: The symbol of the final calculated value, which is returned.
- `instance::Any`: The instance that this tape is generated for.
- `machine::Machine`: The [`Machine`](@ref) that this tape is generated for.
"""
struct Tape{INPUT}
    input_assign_code::Vector{FunctionCall}
    schedule::Vector{FunctionCall}
    output_symbol::Symbol
    instance::Any
    machine::Machine
end
