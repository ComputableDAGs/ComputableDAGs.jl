#!/bin/fish

cd (dirname (status -f))

for dir in (find . -maxdepth 1 -mindepth 1 -type d)
    cd $dir
    echo "=== Running $dir ==="
    julia --project=../../ run.jl > data/bench_(date +%y_%m_%d_%H_%M).log 2>&1 || echo "Run failed.\n\n"
    cd -
end
