#ifndef STRING_H
#define STRING_H

#include <stdio.h>
#include <stdbool.h>

#define NO_STRING ((String){0, 0, 0})

typedef struct 
{
    char* data;
    int length;
    int capacity;
} String;

String String_New();

String* String_From(char* str);

void String_Append(String* str, char c);

bool String_Contains(String str, char c);

void String_fprint(FILE* out, String str);

bool String_Compare(String* a, String* b);

#endif