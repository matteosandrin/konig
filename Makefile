konig.native:
	ocamlbuild -use-ocamlfind konig.native
	
ast_test:
	./_build/konig.native -a ./pretty_ast_test.ko

sast_test:
	./_build/konig.native -s ./pretty_sast_test.ko

clean:
	ocamlbuild -clean