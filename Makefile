parser:
	ocamlyacc parser.mly
	
clean:
	rm parser.ml parser.mli