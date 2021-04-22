# Path to the LLVM compiler
LLC=/usr/local/opt/llvm/bin/llc
# Path to the C compiler
CC=cc
GCC=gcc
targets := $(wildcard *.mll) $(wildcard *.mly) $(wildcard *.ml)
OUT=k.out

all: konig.native konig.o

konig.native:
	opam config exec -- \
	ocamlbuild -use-ocamlfind konig.native -package llvm -package llvm.analysis -package llvm.bitreader
	$(GCC) -c konig.c
	clang -emit-llvm -c konig.c -o konig.bc
	
ast_test:
	./_build/konig.native -a ./pretty_ast_test.ko

sast_test:
	./_build/konig.native -s ./pretty_sast_test.ko

clean:
	ocamlbuild -clean
	rm -f *.o *.bc