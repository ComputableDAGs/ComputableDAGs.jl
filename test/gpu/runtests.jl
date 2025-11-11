"""
This file sets up GPU testing. By default, it will check if GPU libraries are installed and
functional, and execute the unit tests then. Additionally, if an environment variable is set
("TEST_<GPU> = 1"), the tests will fail if the library is not functional.
"""

using Pkg
using ComputableDAGs
using KernelAbstractions
ComputableDAGs.init(@__MODULE__)
ComputableDAGs.init_kernel(@__MODULE__)

include("../utils.jl")

SETUPS = TestSetup[]

# check if we test with CPU
cpu_tests = _is_test_platform_active(["TEST_KACPU"], true)
if cpu_tests
    backends = (
        CPU(),
        CPU(static = true),
    )

    push!(SETUPS, TestSetup(backends, (Vector,), (Float16, Float32, Float64)))
    @info "Testing with CPU backend"
else
    @info "CPU tests skipped."
end

# check if we test with Metal
metal_tests = _is_test_platform_active(["TEST_METAL"], false)
metal_installed = "Metal" in keys(Pkg.project().dependencies)
if metal_tests

    metal_installed ? nothing : Pkg.add("Metal")

    using Metal

    if Metal.functional()
        push!(SETUPS, TestSetup(MetalBackend(), (MtlVector,), (Float16, Float32)))
        @info "Testing with Metal backend"
    else
        @error "Metal backend is not functional (Metal.functional() == false)"
        @test false
    end

else
    metal_installed ? @warn("Metal is installed, but tests skipped.") :
        @info("Metal tests skipped.")
end

# check if we test with CUDA
cuda_tests = _is_test_platform_active(["TEST_CUDA"], false)
cuda_installed = "CUDA" in keys(Pkg.project().dependencies)
if cuda_tests

    cuda_installed ? nothing : Pkg.add("CUDA")

    using CUDA

    if CUDA.functional()
        backends = (
            CUDABackend(),
            CUDABackend(prefer_blocks = true),
            CUDABackend(always_inline = true),
            CUDABackend(prefer_blocks = true, always_inline = true),
        )

        push!(SETUPS, TestSetup(backends, (CuVector,), (Float16, Float32, Float64)))
        @info "Testing with CUDA backend"
    else
        @error "CUDA backend is not functional (CUDA.functional() == false)"
        @test false
    end

else
    cuda_installed ? @warn("CUDA is installed, but tests skipped.") :
        @info("CUDA tests skipped.")
end

# check if we test with oneAPI
oneapi_tests = _is_test_platform_active(["TEST_ONEAPI"], false)
oneapi_installed = "oneAPI" in keys(Pkg.project().dependencies)
if oneapi_tests

    oneapi_installed ? nothing : Pkg.add("oneAPI")

    using oneAPI

    if oneAPI.functional()
        # check if f64 is supported
        element_types = if oneL0.module_properties(oneAPI.device()).fp64flags &
                oneL0.ZE_DEVICE_MODULE_FLAG_FP64 == oneL0.ZE_DEVICE_MODULE_FLAG_FP64
            (Float32, Float64)
        else
            (Float32,)
        end

        push!(SETUPS, TestSetup(oneAPIBackend(), (oneVector,), element_types))
        @info "Testing with oneAPI backend"
    else
        @error "oneAPI backend is not functional (oneAPI.functional() == false)"
        @test false
    end

else
    oneapi_installed ? @warn("oneAPI is installed, but tests skipped.") :
        @info("oneAPI tests skipped.")
end

# check if we test with AMDGPU
amdgpu_tests = _is_test_platform_active(["TEST_AMDGPU"], false)
amdgpu_installed = "AMDGPU" in keys(Pkg.project().dependencies)
if amdgpu_tests

    amdgpu_installed ? nothing : Pkg.add("AMDGPU")

    using AMDGPU

    if AMDGPU.functional()
        push!(SETUPS, TestSetup(ROCBackend(), (ROCVector,), (Float32, Float64)))
        @info "Testing with AMDGPU backend"
    else
        @error "AMDGPU backend is not functional (AMDGPU.functional() == false)"
        @test false
    end

else
    amdgpu_installed ? @warn("AMDGPU is installed, but tests skipped.") :
        @info("AMDGPU tests skipped.")
end

# from here on, we cannot use safe test sets or we would unload the GPU libraries again
if isempty(SETUPS)
    @info """No backends are enabled, skipping tests...
    To test a backend, please use 'TEST_<BACKEND> = 1 julia ...' for one of BACKEND=[CPU, CUDA, AMDGPU, METAL, ONEAPI]"""
else
    include("../fibonacci/impl.jl")

    include("fibonacci.jl")
end
