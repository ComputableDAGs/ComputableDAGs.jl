"""
    NULL_UUID

A constant value for a UUID that is considered "null", or invalid. Used in place of `Optional` UUIDs where invalid UUIDs can appear.

See also [`isnull`](@ref).
"""
const NULL_UUID = UUID(0)

"""
    MANAGEMENT_PORT

A fixed port used for initial exchange of each device's socket info.
"""
MANAGEMENT_PORT = 15678

"""
    INITIALIZED_MODULES

Vector of modules to keep track which have been initialized with RuntimeGeneratedFunctions.jl.
"""
INITIALIZED_MODULES = Module[]

const EXPR_SYM = Symbol("__expr_cache__")

"""
    isnull(id::UUID)

Check whether a given UUID is "null", or invalid.

See also [`NULL_UUID`](@ref).
"""
function isnull(id::UUID)
    return id == NULL_UUID
end

"""
    init(mod::Module)

Call this function once after `using ComputableDAGs` at the top level of your
project. This is necessary to make `RuntimeGeneratedFunctions` work.

Usually, it is used like this:
```julia
using ComputableDAGs
ComputableDAGs.init(@__MODULE__)

# your project
```

!!! note
    This can be skipped when there is a world age increase between the
    [`compute_function`](@ref) call and the call to the generated function.
    Generally, this is often the case in the REPL or in scripts, but not in a
    module.
"""
function init(mod::Module)
    if !(mod in ComputableDAGs.INITIALIZED_MODULES)
        RuntimeGeneratedFunctions.init(mod)
        push!(ComputableDAGs.INITIALIZED_MODULES, mod)
    end

    mod.eval(:($EXPR_SYM = Dict{Val, Expr}()))

    mod.eval(Meta.parse("
    @generated function _compute_expr(input::T, val::Val) where {T}
        return $mod.$EXPR_SYM[val()]
    end
    "))

    return nothing
end
