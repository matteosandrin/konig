# Path to the LLVM compiler
LLC=/usr/local/opt/llvm/bin/llc
# Path to the C compiler
CC=cc
GCC=gcc
targets := $(wildcard **/*.mll) $(wildcard **/*.mly) $(wildcard **/*.ml)

all: clean konig.native konig.o

konig.native: $(targets)
	opam config exec -- \
	ocamlbuild -use-ocamlfind src/konig.native \
	-Is src/ast,src/sast -r \
	-package llvm -package llvm.analysis -package llvm.bitreader
	$(GCC) -c src/konig.c
	clang -emit-llvm -c src/konig.c -o konig.bc
	
ast_test:
	./konig.native -a ./src/ast/pretty_ast_test.ko

sast_test:
	./konig.native -s ./src/sast/pretty_sast_test.ko

clean:
	ocamlbuild -clean
	rm -f *.o *.bc