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

if command -v brew &> /dev/null
then
    LIBS="-L$(brew --prefix graphviz)/lib -lgvc -lcgraph -lcdt"
else
    LIBS=""
fi

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
$GCC -c src/konig.c
$GCC -o $INPUT.out $LIBS $INPUT.s konig.o
rm $INPUT.s $INPUT.ll