#ifndef NODE_H
#define NODE_H

#include "list.h"
#include "string.h"
#include <stdio.h>

typedef enum nodeType 
{
    HEADER,
    PARAGRAPH,
    CODEBLOCK,
    IMAGE,
    TEXT,
    ITALIC,
    BOLD,
    CODE,
    LINK
} NodeType;

typedef struct node 
{
    NodeType type;
    int size;
    List* children;
    String text;
    String url;
} Node;

Node* Node_New(NodeType type, int size, List* children, String text, String url);

void Node_WriteHTML(FILE* out, Node* node);

#endif