#ifndef TOKEN_H
#define TOKEN_H

#include "string.h"

typedef struct token 
{
    String data;
    int line;
    int col;
} Token;

Token* Token_New(String data, int line, int col);

#endif