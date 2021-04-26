# Konig – A Graph Programming Language

## Dependencies

In order to support the graph visualization functionality, Konig depends on the [Graphviz](https://graphviz.org/) library.
The Graphviz library can be installed with the following command on Mac:

```
brew install graphviz
```

On Linux it can be installed with

```
sudo apt install graphviz libgraphviz-dev libcgraph6
```

If installing on Linux, please update the `$GRAPHVIZ_PATH` variable in `./compile.sh`, with the correct path to the `graphviz` library (usually `/usr/include/graphviz`).
Konig will compile and run successfully without the Graphviz library, but the `viz()` function will not be available.


## Compiling

How to compile the `demo.ko` progam:

1. Compile the Konig programming language by running `make`
2. Compile the demo program, by running `./compile.sh demo.ko`
3. Execute the demo program by running `./demo.out`. The output is:
  
```
Matteo  
Delilah  
Lord   
```

## Testing

In order to run the testing suite, execute the following command:

```
make test
```