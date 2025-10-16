# ComputableDAGs.jl

[![tests](https://github.com/ComputableDAGs/ComputableDAGs.jl/actions/workflows/unit_tests.yml/badge.svg?branch=main)](https://github.com/ComputableDAGs/ComputableDAGs.jl/actions/workflows/unit_tests.yml/)
[![codecov](https://codecov.io/gh/ComputableDAGs/ComputableDAGs.jl/graph/badge.svg?token=2585ZA92QK)](https://codecov.io/gh/ComputableDAGs/ComputableDAGs.jl)
[![docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://ComputableDAGs.github.io/ComputableDAGs.jl/dev/)
[![code style: runic](https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black)](https://github.com/fredrikekre/Runic.jl)
[![doi](https://rodare.hzdr.de/badge/848178532.svg)](https://rodare.hzdr.de/badge/latestdoi/848178532)

Represent computations as Directed Acyclic Graphs (DAGs), analyze and optimize them, then compile to native code and run!

## Installation

As a registered julia package, you can install it using

```Julia-repl
(@v1.10) pkg> add ComputableDAGs
```

## Usage

For all the julia calls, use `-t n` to give julia `n` threads.

Instantiate the project first:

```bash
julia --project=./ -e 'import Pkg; Pkg.instantiate()'
```

### Run Tests

To run all tests, run

```bash
julia --project=./ -e 'import Pkg; Pkg.test()' -O0
```

## Acknowledgements and Funding

This work was partly funded by the Center for Advanced Systems Understanding (CASUS) that is financed by Germany’s Federal Ministry of Research, Technology and Space (BMFTR) and by the Saxon Ministry for Science, Culture and Tourism (SMWK) with tax funds on the basis of the budget approved by the Saxon State Parliament.

I'd also like to thank Michael Bussmann for funding the project, and Simeon Ehrig and Rene Widera for help with the fundamental design of the package. Finally, I would like to thank Uwe Hernandez Acosta for supervising the initial work and many discussions on how to improve it.
