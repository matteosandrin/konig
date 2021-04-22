#!/bin/bash

echo ""
echo "  ######################################"
echo "  #                                    #"
echo "  #   Welcome to the Konig compiler!   #"
echo "  #                                    #"
echo "  ######################################"
echo ""

LLC=/usr/local/opt/llvm/bin/llc
GCC=gcc

if [ "$#" -ne 1 ]; then
    echo "ERROR: incorrect number of parameters"
    echo "Usage:"
    echo "       ./compile.sh <input_file>"
    exit 1
fi

filename="$(basename -- $1)"
INPUT="${filename%.*}"

set -x

./konig.native -c $1 > "$INPUT.ll"
$LLC -relocation-model=pic $INPUT.ll > $INPUT.s
$GCC -c konig.c
$GCC -o $INPUT.out $INPUT.s konig.o
rm $INPUT.s $INPUT.ll