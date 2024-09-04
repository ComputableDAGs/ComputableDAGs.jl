# Devices

## Interface
```@autodocs
Modules = [GraphComputing]
Pages = ["devices/interface.jl"]
Order = [:type, :constant, :function]
```

## Detect
```@autodocs
Modules = [GraphComputing]
Pages = ["devices/detect.jl"]
Order = [:function]
```

## Measure
```@autodocs
Modules = [GraphComputing]
Pages = ["devices/measure.jl"]
Order = [:function]
```

## Implementations

### General
```@autodocs
Modules = [GraphComputing]
Pages = ["devices/impl.jl"]
Order = [:type, :function]
```

### NUMA
```@autodocs
Modules = [GraphComputing]
Pages = ["devices/numa/impl.jl"]
Order = [:type, :function]
```

### CUDA
For CUDA functionality to be available, the `CUDA.jl` package must be installed separately, as it is only a weak dependency.

### ROCm
For ROCm functionality to be available, the `AMDGPU.jl` package must be installed separately, as it is only a weak dependency.

### oneAPI
For oneAPI functionality to be available, the `oneAPI.jl` package must be installed separately, as it is only a weak dependency.
