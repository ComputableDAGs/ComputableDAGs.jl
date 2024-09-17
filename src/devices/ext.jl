# file for struct definitions used by the extensions
# since extensions can't export names themselves

"""
    CUDAGPU <: AbstractGPU

Representation of a specific CUDA GPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.

!!! note
    This requires CUDA to be loaded to be useful.
"""
mutable struct CUDAGPU <: AbstractGPU
    device::Any # CuDevice
    cacheStrategy::CacheStrategy
    FLOPS::Float64
end

"""
    oneAPIGPU <: AbstractGPU

Representation of a specific Intel GPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.

!!! note
    This requires oneAPI to be loaded to be useful.
"""
mutable struct oneAPIGPU <: AbstractGPU
    device::Any # oneAPI.oneL0.ZeDevice
    cacheStrategy::CacheStrategy
    FLOPS::Float64
end

"""
    ROCmGPU <: AbstractGPU

Representation of a specific AMD GPU that code can run on. Implements the [`AbstractDevice`](@ref) interface.

!!! note
    This requires AMDGPU to be loaded to be useful.
"""
mutable struct ROCmGPU <: AbstractGPU
    device::Any # HIPDevice
    cacheStrategy::CacheStrategy
    FLOPS::Float64
end
