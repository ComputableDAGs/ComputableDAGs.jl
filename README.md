# ComputableDAGs.jl

[![Build Status](https://github.com/ComputableDAGs/ComputableDAGs.jl/actions/workflows/unit_tests.yml/badge.svg?branch=main)](https://github.com/ComputableDAGs/ComputableDAGs.jl/actions/workflows/unit_tests.yml/)
[![Doc Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ComputableDAGs.github.io/ComputableDAGs.jl/dev/)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![DOI](https://rodare.hzdr.de/badge/848178532.svg)](https://rodare.hzdr.de/badge/latestdoi/848178532)

Represent computations as Directed Acyclic Graphs (DAGs), analyze and optimize them, then compile to native code and run!

## Usage

For all the julia calls, use `-t n` to give julia `n` threads.

Instantiate the project first:

`julia --project=./ -e 'import Pkg; Pkg.instantiate()'`

### Run Tests

To run all tests, run

`julia --project=./ -e 'import Pkg; Pkg.test()' -O0`

## Concepts

### Generate Operations from chains

We assume we have a (valid) DAG given. We can generate all initially possible graph operations from it, and we can calculate the graph properties like compute effort and total data transfer.

Goal: For some operation, regenerate possible operations after that one has been applied, but without having to copy the entire graph. This would be helpful for optimization algorithms to try paths of optimizations and build up tree structures, like for example chess computers do.

Idea: Keep the original graph, a list of possible operations at the current state, and a queue of applied operations together. The "actual" graph is then the original graph with all operations in the queue applied. We can push and pop new operations to/from the queue, automatically updating the graph's global metrics and possible optimizations from there.

## Acknowledgements and Funding 

This work was partly funded by the Center for Advanced Systems Understanding (CASUS) that is financed by Germany’s Federal Ministry of Education and Research (BMBF) and by the Saxon Ministry for Science, Culture and Tourism (SMWK) with tax funds on the basis of the budget approved by the Saxon State Parliament.

I'd also like to thank Michael Bussmann for funding the project, and Simeon Ehrig and Rene Widera for help with the fundamental design of the package.
