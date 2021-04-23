#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define NODE_ID_LEN 32

// Type definitions

typedef struct Array {
    int length;
    void** start;
} array;

typedef struct Node {
    char* id;
    void* data;
} node;

typedef struct Graph {
    char* id;
    array* nodes;
    array* edges;
} graph;

// Function signatures

array* init_array();
int append_array(array* a, void* elem);
void* get_array(array* a, int index);

node* init_node(void* data);
graph* init_graph();

node* find_node_by_id(char* id, graph* g);
graph* add_node(node* n, graph* g);
graph* del_node(node* n, graph* g);

void random_id(char *dest, int length);
int print_node(node* n);
int print_graph(graph* g);

// Function bodies

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

node* init_node(void* data) {
    node* n =  (node *) malloc(sizeof(node));
    char* id = (char *) malloc(sizeof(char) * (NODE_ID_LEN + 1));
    random_id(id, NODE_ID_LEN);
    n->id = id;
    n->data = data;
    // printf("node initialized successfully!\n");
    // printf("node id: %s\n", n->id);
    return n;
}

graph* init_graph() {
    graph* g = (graph *) malloc(sizeof(graph));
    char* id = (char *) malloc(sizeof(char) * (NODE_ID_LEN + 1));
    random_id(id, NODE_ID_LEN);
    g->id = id;
    g->nodes = init_array();
    g->edges = init_array();
    return g;
}

node* find_node_by_id(char* id, graph* g) {
    for (int i = 0; i < g->nodes->length; i++) {
        node* n = g->nodes->start[i];
        if (strcmp(n->id, id) == 0)
            return n;
    }
    return NULL;
}

graph* add_node(node* n, graph* g) {
    if (find_node_by_id(n->id, g) != NULL) {
        // the node is already in this graph
        return g;
    }

    append_array(g->nodes, n);
    return g;
}

graph* del_node(node* n, graph* g) {
    return NULL;
}

// Helper functions

void random_id(char *dest, int length) {
    char charset[] = "0123456789"
                     "abcdefghijklmnopqrstuvwxyz"
                     "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    while (length > 0) {
        int index = (double) rand() / RAND_MAX * (sizeof charset - 1);
        *dest = charset[index];
        dest++;
        length--;
    }
    *dest = '\0';
}

int print_node(node* n) {
    printf("node: { id=\"%s\" }\n", n->id);
    return 0;
}

int print_graph(graph* g) {
    printf("graph: { id=\"%s\" }\n", g->id);
    printf("    %d nodes: {\n", g->nodes->length);
    for (int i = 0; i < g->nodes->length; i++)
    {
        node* n = g->nodes->start[i];
        printf("        ");
        print_node(n);
    }
    printf("    }\n");
    printf("    %d edges: {\n", g->edges->length);
    // TODO: print out edges
    printf("    }\n");
    return 0;
}
