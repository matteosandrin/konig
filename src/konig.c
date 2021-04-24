#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define ID_LEN 32

// Type definitions

typedef struct Elem {
    void* data;
    struct Elem* next;
    struct Elem* prev;
} elem;

typedef struct Array {
    int length;
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

// Function signatures

array* init_array();
int append_array(array* a, void* data);
int delete_array(array* a, elem* e);
void* get_array(array* a, int index);

node* init_node(void* data);
edge* init_edge(node* from, node* to, bool directed, double weight);
graph* init_graph();

elem* find_elem_by_id(char* id, graph* g);
graph* add_node(node* n, graph* g);
graph* del_node(node* n, graph* g);

elem* find_elem_by_from_to(graph* g, node* from, node* to);
edge* set_edge_helper(graph* g, node* from, node* to, bool directed, double weight);
edge* set_edge(graph* g, node* from, node* to, double weight);
edge* set_dir_edge(graph* g, node* from, node* to, double weight);
edge* get_edge(graph* g, node* from, node* to);
edge* del_edge(graph* g, node* from, node* to);
edge* update_edge(graph* g, node* from, node* to, double weight);

void* get_node_val(node* n);
char* get_node_id(node* n);
bool get_edge_directed(edge* e);
double get_edge_weight(edge* e);
char* get_edge_id(edge* e);

void random_id(char *dest, int length);
int print_node(node* n);
int print_graph(graph* g);

// Function bodies

array* init_array() {
    array* arr = (array *) malloc(sizeof(array));
    arr->length = 0;
    arr->head = NULL;
    arr->tail = NULL;
    return arr;
}

int append_array(array* a, void* data) {
    int new_len = a->length + 1;

    elem* new_elem = (elem*) malloc(sizeof(elem));
    new_elem->data = data;
    new_elem->prev = a->tail;
    new_elem->next = NULL;

    if (a->length == 0) {
        a->head = new_elem;
    } else {
        a->tail->next = new_elem;
    }

    a->tail = new_elem;
    a->length++;
    return 0;
}

int delete_array(array* a, elem* e) {
    if (a->head == NULL || e == NULL )
        return 0;
    if (a->head == e)
        a->head = e->next;
    if (e->next != NULL)
        e->next->prev = e->prev;
    if (e->prev != NULL)
        e->prev->next = e->next;
    if (a->tail == e)
        a->tail = e->prev;
    free(e);
    a->length--;
    return 0;
}

void* get_array(array* a, int index) {
    // printf("get_array\n");
    // printf("get_idx: %d %d\n", index, (a->length)-1);
    
    if (index > (a->length)-1) {
        fprintf(stderr, "ERROR: array index out of bounds: %d\n", index);
        exit(1);
    }

    elem* curr = a->head;
    while (curr && index) {
        index--;
        curr = curr->next;
    }
    
    return curr->data;
}

node* init_node(void* data) {
    node* n =  (node *) malloc(sizeof(node));
    char* id = (char *) malloc(sizeof(char) * (ID_LEN + 1));
    random_id(id, ID_LEN);
    n->id = id;
    n->data = data;
    // printf("node initialized successfully!\n");
    // printf("node id: %p\n", n);
    return n;
}

edge* init_edge(node* from, node* to, bool directed, double weight) {
    edge* e = (edge *) malloc(sizeof(edge));
    char* id = (char *) malloc(sizeof(char) * (ID_LEN + 1));
    random_id(id, ID_LEN);
    e->id = id;
    e->from = from;
    e->to = to;
    e->directed = directed;
    e->weight = weight;
    return e;
}

graph* init_graph() {
    graph* g = (graph *) malloc(sizeof(graph));
    char* id = (char *) malloc(sizeof(char) * (ID_LEN + 1));
    random_id(id, ID_LEN);
    g->id = id;
    g->nodes = init_array();
    g->edges = init_array();
    return g;
}

elem* find_elem_by_id(char* id, graph* g) {
    int i = 0;
    int node_count = g->nodes->length;
    elem* curr = g->nodes->head;
    while (curr && i < node_count) {
        node* n = (node*)curr->data;
        if (strcmp(n->id, id) == 0)
            return curr;
        curr = curr->next;
    }
    return NULL;
}

graph* add_node(node* n, graph* g) {
    if (find_elem_by_id(n->id, g) != NULL) {
        // the node is already in this graph
        return g;
    }
    append_array(g->nodes, n);
    return g;
}

graph* del_node(node* n, graph* g) {
    elem* e = find_elem_by_id(n->id, g);
    delete_array(g->nodes, e);
    return g;
}

elem* find_elem_by_from_to(graph* g, node* from, node* to) {
    elem* curr = g->edges->head;
    while (curr) {
        edge* e = (edge*)curr->data;
        if (
            (strcmp(e->from->id, from->id) == 0 && strcmp(e->to->id,   to->id) == 0) ||
            (strcmp(e->to->id,   from->id) == 0 && strcmp(e->from->id, to->id) == 0)
        )
            return curr;
        curr = curr->next;
    }
    return NULL;
}

edge* set_edge_helper(graph* g, node* from, node* to, bool directed, double weight) {
    elem* elem1 = find_elem_by_id(from->id, g);
    elem* elem2 = find_elem_by_id(to->id, g);

    if (elem1 == NULL || elem2 == NULL) {
        fprintf(stderr, "ERROR: attempting to create edge between nodes not in graph\n");
        exit(1);
    }
    
    edge* e = init_edge(from, to, directed, weight);
    append_array(g->edges, e);
    return e;
}

edge* set_edge(graph* g, node* from, node* to, double weight) {
    return set_edge_helper(g, from, to, false, weight);
}

edge* set_dir_edge(graph* g, node* from, node* to, double weight) {
    return set_edge_helper(g, from, to, true, weight);
}

edge* get_edge(graph* g, node* from, node* to) {
    elem *el = find_elem_by_from_to(g, from, to);

    if (el)
        return (edge*)el->data;

    fprintf(stderr, "ERROR: attempting to access non-existing edge\n");
    exit(1);
}

edge* del_edge(graph* g, node* from, node* to) {
    elem *el = find_elem_by_from_to(g, from, to);

    if (el) {
        delete_array(g->edges, el);
        return (edge*)el->data;
    }

    fprintf(stderr, "ERROR: attempting to delete non-existing edge\n");
    exit(1);
}

edge* update_edge(graph* g, node* from, node* to, double weight) {
    elem *el = find_elem_by_from_to(g, from, to);

    if (el) {
        edge *e = el->data;
        e->weight = weight;
        return (edge*)el->data;
    }

    fprintf(stderr, "ERROR: attempting to update non-existing edge\n");
    exit(1);
}

void* get_node_val(node* n) {
    return n->data;
}

char* get_node_id(node* n) {
    return n->id;
}

bool get_edge_directed(edge* e) {
    return e->directed;
}

double get_edge_weight(edge* e) {
    return e->weight;
}

char* get_edge_id(edge* e) {
    return e->id;
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
    printf("node: {\n");
    printf("    id=\"%s\"\n", n->id);
    printf("}\n");
    return 0;
}

int print_edge(edge* e) {
    printf("edge: {\n");
    printf("    id   =\"%s\",\n",e->id);
    printf("    from =\"%s\",\n",e->from->id);
    printf("    to   =\"%s\",\n",e->to->id);
    printf("    dir  = %s,\n",e->directed ? "true" : "false");
    printf("    w    = %f,\n",e->weight);
    printf("}\n");
    return 0;
}

int print_graph(graph* g) {
    printf("graph: { id=\"%s\" }\n", g->id);
    printf("    %d nodes: {\n", g->nodes->length);
    int i = 0;
    int node_count = g->nodes->length;
    elem* curr = g->nodes->head;
    while (curr && i < node_count) {
        node* n = (node*)curr->data;
        print_node(n);
        curr = curr->next;
    }
    printf("    }\n");

    printf("    %d edges: {\n", g->edges->length);
    int j = 0;
    int edge_count = g->edges->length;
    curr = g->edges->head;
    while (curr && j < edge_count) {
        edge* e = (edge*)curr->data;
        print_edge(e);
        curr = curr->next;
    }
    printf("    }\n\n");
    return 0;
}
