#include "konig.h"
#include <graphviz/cgraph.h>
#include <graphviz/gvc.h>

int32_t visualize_graph_helper(graph* g, char* path) {

    Agraph_t* G;
    GVC_t* gvc;
    Agnode_t* agnodes[g->nodes->length];
    FILE *f;

    gvc = gvContext();
    G = agopen("graph", Agundirected, NULL);
    f = fopen(path, "wb");

    int32_t i = 0;
    elem* curr = g->nodes->head;
    while (curr) {
        node* n = (node*)curr->data;
        agnodes[i] = agnode(G, n->id, true);
        curr = curr->next;
        i++;
    }

    i = 0;
    curr = g->edges->head;
    agattr(G, AGEDGE, "label", "0");
    while (curr) {
        edge* e = (edge*)curr->data;
        char* weight = (char*) malloc(sizeof(char) * 10);
        snprintf(weight, 10, "%.3f", e->weight);
        int32_t from_idx = find_index_by_id(e->from->id, g->nodes);
        int32_t to_idx = find_index_by_id(e->to->id, g->nodes);
        Agedge_t *agE = agedge(G, agnodes[from_idx], agnodes[to_idx], "", true);
        agset(agE, "label", weight);
        curr = curr->next;
        i++;
        free(weight);
    }

    gvLayout (gvc, G, "dot");
    gvRender(gvc, G, "pdf", f);
    gvFreeLayout(gvc, G);
    agclose(G);
    fclose(f);
    return 0;
}