# Devices

## Interface
```@autodocs
Modules = [ComputableDAGs]
Pages = ["devices/interface.jl"]
Order = [:type, :constant, :function]
```

## Detect
```@autodocs
Modules = [ComputableDAGs]
Pages = ["devices/detect.jl"]
Order = [:function]
```

## Measure
```@autodocs
Modules = [ComputableDAGs]
Pages = ["devices/measure.jl"]
Order = [:function]
```

## Implementations

### General
```@autodocs
Modules = [ComputableDAGs]
Pages = ["devices/impl.jl"]
Order = [:type, :function]
```

### NUMA
```@autodocs
Modules = [ComputableDAGs]
Pages = ["devices/numa/impl.jl"]
Order = [:type, :function]
```

### CUDA
For CUDA functionality to be available, the `CUDA.jl` package must be installed separately, as it is only a weak dependency.

### ROCm
For ROCm functionality to be available, the `AMDGPU.jl` package must be installed separately, as it is only a weak dependency.

### oneAPI
For oneAPI functionality to be available, the `oneAPI.jl` package must be installed separately, as it is only a weak dependency.
