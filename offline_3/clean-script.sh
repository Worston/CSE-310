#!/bin/bash

# Enable extended globbing for pattern matching
shopt -s extglob

# Loop through all files that do NOT match *.sh, *.g4, or Ctester.cpp
for file in !(*.sh|*.txt|*.g4|Main.java|SymbolInfo.java|ScopeTable.java|SymbolTable.java|SDBMHash.java|HashFunction.java); do
    # Only delete if it's a regular file
    if [[ -f "$file" ]]; then
        rm -f "$file"
    fi
done

# Remove the 'output' directory if it exists
# rm -rf output
