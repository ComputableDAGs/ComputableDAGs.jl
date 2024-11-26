#!/bin/fish

cd (dirname (status -f))

for dir in (find . -maxdepth 1 -mindepth 1 -type d)
    cd $dir
    echo "=== Plotting $dir ==="
    julia --project=../../ plot.jl || echo "Plot failed.\n\n"
    cd -
end
