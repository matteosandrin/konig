#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define ID_LEN 8

#ifndef IS_GRAPHVIZ_AVAILABLE
#define IS_GRAPHVIZ_AVAILABLE 0
#endif

// Type definitions

typedef struct Elem {
    void* data;
    struct Elem* next;
    struct Elem* prev;
} elem;

typedef struct Array {
    int32_t length;
    elem* head;
    elem* tail;
} array;

typedef struct Node {
    char* id;
    void* data;
} node;

typedef struct Edge {
    char* id;
    node* from;
    node* to;
    bool directed;
    double weight;
} edge;

typedef struct Graph {
    char* id;
    array* nodes;
    array* edges;
} graph;

array* init_array();
int32_t append_array(array* a, void* data);
int32_t delete_array(array* a, elem* e);
void* get_array(array* a, int32_t index);
int32_t pop_array(array *a, int32_t index);

node* init_node(void* data);
edge* init_edge(node* from, node* to, bool directed, double weight);
graph* init_graph();
array* neighbors(graph* g, node* n);

elem* find_elem_by_id(char* id, array* nodes);
int32_t find_index_by_id(char* id, array* a);
graph* add_node(node* n, graph* g);
graph* del_node(node* n, graph* g);

elem* find_elem_by_from_to(graph* g, node* from, node* to);
edge* set_edge_helper(graph* g, node* from, node* to, bool directed, double weight);
edge* set_edge(graph* g, node* from, node* to, double weight);
edge* set_dir_edge(graph* g, node* from, node* to, double weight);
edge* get_edge(graph* g, node* from, node* to);
edge* del_edge(graph* g, node* from, node* to);
edge* update_edge(graph* g, node* from, node* to, double weight);

int32_t get_array_length(array* a);
void* get_node_val(node* n);
char* get_node_id(node* n);
bool get_edge_directed(edge* e);
double get_edge_weight(edge* e);
char* get_edge_id(edge* e);
array* get_graph_nodes(graph* g);
array* get_graph_edges(graph* g);

char* random_id(int32_t length);
int32_t print_node(node* n);
int32_t print_edge(edge* e);
int32_t print_graph(graph* g);
int32_t visualize_graph(graph* g, char* path);
int32_t visualize_graph_helper(graph* g, char* path);