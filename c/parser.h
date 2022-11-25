#ifndef PARSER_H
#define PARSER_H

#include "list.h"
#include "string.h"

void Parser_Init(String contents);
List* Parser_ParseDocument();

#endif