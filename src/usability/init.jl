"""
    INITIALIZED_MODULES

Vector of modules to keep track which have been initialized with RuntimeGeneratedFunctions.jl.
"""
INITIALIZED_MODULES = Module[]

"""
    init(mod::Module)

Call this function once after `using ComputableDAGs` at the top level of your project. This is necessary to make `RuntimeGeneratedFunctions` work.

Usually, it is used like this:
```julia
using ComputableDAGs
ComputableDAGs.init(@__MODULE__)

# your project
```

!!! note
    This can be skipped when there is a world age increase between the [`compute_function`](@ref) call and the call to the generated function. Generally, this is often the case in the REPL or in scripts, but not in a module.
"""
function init(mod::Module)
    if !(mod in ComputableDAGs.INITIALIZED_MODULES)
        RuntimeGeneratedFunctions.init(mod)
        push!(ComputableDAGs.INITIALIZED_MODULES, mod)
    end
    return nothing
end
