# Path to the LLVM compiler
LLC=/usr/local/opt/llvm/bin/llc
# Path to the C compiler
CC=cc
targets := $(wildcard *.mll) $(wildcard *.mly) $(wildcard *.ml)
OUT=k.out

konig.native: $(targets)
	opam config exec -- \
	ocamlbuild -use-ocamlfind konig.native -package llvm -package llvm.analysis

compile:
	./konig.native -c $(FILE) > temp.ll
	$(LLC) -relocation-model=pic temp.ll > temp.s
	$(CC) -o $(OUT) temp.s
	rm temp.ll temp.s
	
ast_test:
	./_build/konig.native -a ./pretty_ast_test.ko

sast_test:
	./_build/konig.native -s ./pretty_sast_test.ko

clean:
	ocamlbuild -clean