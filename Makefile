parser:
	ocamlyacc -v parser.mly
	
clean:
	rm parser.ml parser.mli parser.output