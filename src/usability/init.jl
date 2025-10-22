"""
    INITIALIZED_MODULES

Vector of modules to keep track which have been initialized with RuntimeGeneratedFunctions.jl.
"""
INITIALIZED_MODULES = Module[]

function init(mod::Module)
    if !(mod in ComputableDAGs.INITIALIZED_MODULES)
        RuntimeGeneratedFunctions.init(mod)
        push!(ComputableDAGs.INITIALIZED_MODULES, mod)
    end
    return nothing
end
