#include <stdio.h>
#include <stdlib.h>

typedef struct Array {
    int length;
    void* start;
} array;

array* init_array() {
    array* arr = (array *) malloc(sizeof(array));
    arr->length = 0;
    arr->start = NULL;
    return arr;
}