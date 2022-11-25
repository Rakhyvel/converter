#include "node.h"
#include "string.h"
#include <stdlib.h>

Node* Node_New(NodeType type, int size, List* children, String text, String url)
{
    Node* retval = malloc(sizeof(Node));
    retval->type = type;
    retval->size = size;
    retval->children = children;
    retval->text = text;
    retval->url = url;
    return retval;
}

void Node_WriteHTML(FILE* out, Node* node)
{
    switch (node->type) 
    {
    case HEADER: 
    {
        fprintf(out, "<h%d>", node->size);
        forall(elem, node->children)
        {
            Node_WriteHTML(out, elem->data);
        }
        fprintf(out, "</h%d>\n", node->size);
        break;
    }
    case PARAGRAPH: 
    {
        fprintf(out, "<p>");
        forall(elem, node->children)
        {
            Node_WriteHTML(out, elem->data);
        }
        fprintf(out, "</p>\n\n");
        break;
    }
    case CODEBLOCK: 
    {
        fprintf(out, "<pre><code>");
        String_fprint(out, node->text);
        fprintf(out, "</code></pre>\n\n");
        break;
    }
    case IMAGE: 
    {
        fprintf(out, "<img src=\"");
        String_fprint(out, node->url);
        fprintf(out, "\" alt=\"");
        String_fprint(out, node->text);
        fprintf(out, "\" />");
        break;
    }
    case TEXT: 
    {
        String_fprint(out, node->text);
        break;
    }
    case ITALIC: 
    {
        fprintf(out, "<em>");
        forall(elem, node->children)
        {
            Node_WriteHTML(out, elem->data);
        }
        fprintf(out, "</em>");
        break;
    }
    case BOLD: 
    {
        fprintf(out, "<strong>");
        forall(elem, node->children)
        {
            Node_WriteHTML(out, elem->data);
        }
        fprintf(out, "</strong>");
        break;
    }
    case CODE: 
    {
        fprintf(out, "<code>");
        String_fprint(out, node->text);
        fprintf(out, "</code>");
        break;
    }
    case LINK: 
    {
        fprintf(out, "<a href=\"");
        String_fprint(out, node->url);
        fprintf(out, "\">");
        String_fprint(out, node->text);
        fprintf(out, "</a>");
        break;
    }
    }
}