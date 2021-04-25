# Konig – A Graph Programming Language

## Dependencies

In order to support the graph visualization functionality, Konig depends on the `graphviz` library.
The `graphviz` library must be installed with the following command on Mac:

```
brew install graphviz
```

On Linux it can be installed with:

```
sudo apt install graphviz
```

## Compiling

How to compile the "Hello World" progam:

1. Compile the Konig programming language by running `make`
2. Compile the example program, by running `./compile.sh demo.ko`
3. Execute the executable program by running `./demo.out`, the output is:
  
    ```
    Matteo  
    Delilah  
    Lord   
    ```

## Testing

In order to run the testing suite, execute the following commands:

```
make
python3 test.py
```