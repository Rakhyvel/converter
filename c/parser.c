#include "token.h"
#include "node.h"
#include "parser.h"
#include "list.h"
#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

static List* tokens;
static int _index;

static List* parseFormattedText(List* bounds);

static bool isSpecialChar(char c) 
{
    return c == '_' ||
        c == '*' ||
        c == '`' ||
        c == '#' ||
        c == '[' ||
        c == ']' ||
        c == '(' ||
        c == ')' ||
        c == '!';
}

static Token* pop() 
{
    _index++;
    return List_Get(tokens, _index-1);
}

static Token* peek() 
{
    return List_Get(tokens, _index);
}

static Token* accept(char* data) 
{
    String* stringForm = String_From(data);
    String peekToken = peek()->data;
    if (String_Compare(&peekToken, stringForm)) 
    {
        return pop();
    } 
    else 
    {
        return NULL;
    }
}

static void expect(char* data) 
{
    if (!accept(data))
    {
        Token* top = peek();
        if (isSpecialChar(top->data.data[0]))
        {
            fprintf(stderr, "error: %d:%d expected `%s` got ", top->line, top->col, data);
            String_fprint(stderr, top->data);
            fprintf(stderr, ".\n");
        }
        else
        {
            fprintf(stderr, "error: %d:%d expected `%s` got text\n", top->line, top->col, data);
        }
        system("pause");
        exit(1);
    }
}

static String takeUntil(char* sentinel) 
{
    String data = peek()->data;
    data.length = 0;
    while (!accept(sentinel)) 
    {
        data.length += pop()->data.length;
    }
    return data;
}

static Node* parseHeader() 
{
    int size = 1;
    while (accept("#")) 
    {
        size++;
    }
    List* bounds = List_Create();
    List_Append(bounds, String_From("\n"));
    // TODO: free bounds
    return Node_New(HEADER, size, parseFormattedText(bounds), NO_STRING, NO_STRING);
}

static Node* parseParagraph() 
{
    List* bounds = List_Create();
    List_Append(bounds, String_From("\n"));
    // TODO: free bounds
    return Node_New(PARAGRAPH, 0, parseFormattedText(bounds), NO_STRING, NO_STRING);
}

static Node* parseCodeBlock() 
{
    return Node_New(CODEBLOCK, 0, NULL, takeUntil("```"), NO_STRING);
}

static Node* parseImage() 
{
    expect("[");
    String text = pop()->data;
    expect("]");
    expect("(");
    String url = pop()->data;
    expect(")");
    return Node_New(IMAGE, 0, NULL, text, url);
}

static Node* parseItalic(List* bounds) 
{
    List* newBounds = List_Clone(bounds);
    List_Append(newBounds, String_From("*"));
    List_Append(newBounds, String_From("_"));
    List* children = parseFormattedText(newBounds);
    // TODO: free newBounds
    if (!accept("*")) 
    {
        expect("_");
    }
    return Node_New(ITALIC, 0, children, NO_STRING, NO_STRING);
}

static Node* parseBold(List* bounds) 
{
    List* newBounds = List_Clone(bounds);
    List_Append(newBounds, String_From("**"));
    List_Append(newBounds, String_From("__"));
    List* children = parseFormattedText(newBounds);
    // TODO: free newBounds
    if (!accept("**")) 
    {
        expect("__");
    }
    return Node_New(BOLD, 0, children, NO_STRING, NO_STRING);
}

static Node* parseCode() 
{
    return Node_New(CODE, 0, NULL, takeUntil("`"), NO_STRING);
}

static Node* parseLink() 
{
    String text = pop()->data;
    expect("]");
    expect("(");
    String url = pop()->data;
    expect(")");
    return Node_New(LINK, 0, NULL, text, url);
}

static List* parseFormattedText(List* bounds) 
{
    List* retval = List_Create();
    while (!List_Contains(bounds, &peek()->data, &String_Compare)) 
    {
        if (accept("_") || accept("*")) 
        {
            List_Append(retval, parseItalic(bounds));
        } 
        else if (accept("__") || accept("**")) 
        {
            List_Append(retval, parseBold(bounds));
        } 
        else if (accept("`")) 
        {
            List_Append(retval, parseCode());
        } 
        else if (accept("[")) 
        {
            List_Append(retval, parseLink());
        } else 
        {
            List_Append(retval, Node_New(TEXT, 0, NULL, pop()->data, NO_STRING));
        }
    }
    return retval;
}

static Node* parseNode() 
{
    if (accept("#")) 
    {
        return parseHeader();
    } 
    else if (accept("```")) 
    {
        return parseCodeBlock();
    } 
    else if (accept("!")) 
    {
        return parseImage();
    } 
    else if (!accept("\n")) 
    {
        return parseParagraph();
    }
    else
    {
        return NULL;
    }
}

List* Parser_ParseDocument() 
{
    List* retval = List_Create();
    while (_index < tokens->size - 1) 
    {
        Node* node = parseNode();
        if (node) 
        {
            List_Append(retval, node);
        }
    }
    return retval;
}

void Parser_Init(String contents) 
{
    tokens = List_Create();
    _index = 0;

    String data = {contents.data, 1, 0}; // A substring
    int line = 1;
    int col = 1;
    int oldCol = 1;
    char oldC = contents.data[0];
    for (int i = 1; i < contents.length; i++) 
    {
        char c = contents.data[i];
        if (oldC == '\n' || oldC == '\r' || (isSpecialChar(oldC) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r')
        {
            if (!String_Contains(data, '\r'))
            {
                List_Append(tokens, Token_New(data, line, oldCol));
            }
            oldCol = col + 1;
            if (c == '\n')
            {
                line++;
                col = 0;
            }
            data.data += data.length; // data = "";
            while (oldC == '#' && isspace(data.data[0])) 
            {
                i++;
                data.data++;
            }
            data.length = 0;
        }
        data.length++;
        col++;
        oldC = c;
    }
    List_Append(tokens, Token_New(data, line, oldCol));
    char* newline = malloc(1);
    *newline = '\n';
    List_Append(tokens, Token_New((String){newline, 1, 0}, line, oldCol));
}