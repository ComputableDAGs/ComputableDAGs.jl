module oneAPIExt

using ComputableDAGs, oneAPI
using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

# include specialized oneAPI functions here
include("devices/oneapi/impl.jl")

end
