#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

typedef struct Array {
    int length;
    void** start;
} array;

array* init_array();
int append_array(array* a, void* elem);
void* get_array(array* a, int index);

array* init_array() {
    array* arr = (array *) malloc(sizeof(array));
    arr->length = 0;
    arr->start = NULL;
    return arr;
}

int append_array(array* a, void* elem) {
    int new_len = a->length + 1;
    void** new_arr = malloc(sizeof(void*) * new_len);
    if (a->start != NULL) {
        // make a new array, a copy of the old one
        memcpy(new_arr, a->start, sizeof(void*) * a->length);
        free(a->start);
    }
    // copy over the new element
    memcpy(new_arr + new_len - 1, elem, sizeof(void*));

    a->length = new_len;
    a->start = new_arr;    
    // printf("length: %d\n", a->length);
    // for (int i = 0; i < a->length; i++)
    // {
    //     printf("\telem[%d]: %d\n", i, *(int32_t*)((a->start) + i) );
    // }
    // printf("\n");
    return 0;
}

void* get_array(array* a, int index) {
    // printf("get_array\n");
    // printf("get_idx: %d %d\n", index, (a->length)-1);
    
    if (index > (a->length)-1) {
        fprintf(stderr, "ERROR: array index out of bounds: %d\n", index);
        exit(1);
    }
    return (a->start) + index;
}