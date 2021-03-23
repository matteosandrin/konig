konig.native:
	ocamlbuild -use-ocamlfind konig.native
	
ast_test:
	./_build/konig.native -a ./pretty_ast_test.ko

clean:
	ocamlbuild -clean