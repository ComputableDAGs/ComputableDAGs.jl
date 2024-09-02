# GraphComputing.jl

[![Build Status](https://github.com/GraphComputing-jl/GraphComputing.jl/actions/workflows/unit_tests.yml/badge.svg?branch=main)](https://github.com/GraphComputing-jl/GraphComputing.jl/actions/workflows/unit_tests.yml/)
[![Doc Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://graphcomputing-jl.github.io/GraphComputing.jl/dev/)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

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
