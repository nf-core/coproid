#!/usr/bin/env bash

# computeRatio
../bin/computeRatio -c1 ./data/sequences_saureus.out -c2 ./data/sequences_ecoli.out -g1 ecoli.fa -g2 saureus.fa -r1 sequencien.r1.fq -r2 sequencing.r2.fq
pandoc coproID_result.md -o coproID_result.pdf
