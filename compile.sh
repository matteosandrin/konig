#!/bin/bash

echo ""
echo "  ######################################"
echo "  #                                    #"
echo "  #   Welcome to the Konig compiler!   #"
echo "  #                                    #"
echo "  ######################################"
echo ""

GCC=gcc
LLC=/usr/local/opt/llvm/bin/llc
# If on Linux, change this to /usr/include/graphviz 
GRAPHVIZ_PATH=/usr/local/opt/graphviz/lib
LIBS="-L$GRAPHVIZ_PATH -lgvc -lcgraph -lcdt"

if [ "$#" -ne 1 ]; then
    echo "ERROR: incorrect number of parameters"
    echo "Usage:"
    echo "       ./compile.sh <input_file>"
    exit 1
fi

if [ ! -d $GRAPHVIZ_PATH ]; then
    echo "[!] WARNING: Konig cannot find the Graphviz library, so it will be built \
without the viz() function. If you'd like the viz() function to work, please \
install Graphviz, and update the GRAPHVIZ_PATH variable in the \"./compile.sh\" \
script."
    echo ""
fi

filename="$(basename -- $1)"
INPUT="${filename%.*}"

set -x

./konig.native -c $1 > "$INPUT.ll"
$LLC -relocation-model=pic $INPUT.ll > $INPUT.s

if [ -d $GRAPHVIZ_PATH ]; then
    $GCC -DIS_GRAPHVIZ_AVAILABLE=1 -c src/konig.c
    $GCC -DIS_GRAPHVIZ_AVAILABLE=1 -c src/viz.c
    $GCC -DIS_GRAPHVIZ_AVAILABLE=1 -o $INPUT.out $LIBS $INPUT.s konig.o viz.o
else
    $GCC -c src/konig.c
    $GCC -o $INPUT.out $INPUT.s konig.o
fi

rm $INPUT.s $INPUT.ll