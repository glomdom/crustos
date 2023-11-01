#!/bin/sh

printf "lines of forth: "
find . -name "*.f" | grep -v tests | xargs cat | grep -v "^\\\\" | grep -v '^$' | wc -l
printf "lines of c compiler: "
find fs/cc -type f | xargs cat | grep -v "^\\\\" | grep -v '^$' | wc -l
printf "lines of test code: "
find fs/tests -type f | xargs cat | wc -l
printf "lines of assembly: %d LINES OF PURE HELL\n" `cat crust.asm | wc -l`