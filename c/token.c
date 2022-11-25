#include "token.h"
#include <stdlib.h>

Token* Token_New(String data, int line, int col) 
{
    Token* retval = malloc(sizeof(Token));
    retval->data = data;
    retval->line = line;
    retval->col = col;
    return retval;
}