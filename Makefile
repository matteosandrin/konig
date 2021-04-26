# Path to the LLVM compiler
LLC=/usr/local/opt/llvm/bin/llc
# Path to the C compiler
GCC=gcc
targets := $(wildcard **/*.mll) $(wildcard **/*.mly) $(wildcard **/*.ml)

.PHONY: all test ast_test sast_test clean
all: clean konig.native test

konig.native: $(targets)
	opam config exec -- \
	ocamlbuild -use-ocamlfind src/konig.native \
	-Is src/ast,src/sast -r \
	-package llvm -package llvm.analysis -package llvm.bitreader
	$(GCC) -c src/konig.c
	clang -emit-llvm -c src/konig.c -o konig.bc

test:
	python3 test.py

ast_test:
	./konig.native -a ./src/ast/pretty_ast_test.ko

sast_test:
	./konig.native -s ./src/sast/pretty_sast_test.ko

clean:
	ocamlbuild -clean
	rm -f *.o *.bc