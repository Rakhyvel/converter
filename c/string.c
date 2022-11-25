#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include "string.h"
#include <string.h>

String String_New() 
{
    char* data = calloc(10, sizeof(char));
    return (String){data, 0, 10};
}

String* String_From(char* str)
{
    String* retval = malloc(sizeof(String));
    retval->data = str;
    retval->length = strlen(str);
    return retval;
}

void String_Append(String* str, char c) 
{
    if (str->length >= str->capacity) 
    {
        str->capacity *= 2;
        char* new_data = realloc(str->data, str->capacity);
        if (!new_data) {
            fprintf(stderr, "error allocating memory for string append");
            exit(1);
        } else {
            str->data = new_data;
        }
    }
    str->data[str->length] = c;
    str->length++;
}

bool String_Contains(String str, char c) 
{
    for (int i = 0; i < str.length; i++) {
        if (str.data[i] == c) {
            return true;
        }
    }
    return false;
}

void String_fprint(FILE* out, String str)
{
    for (int i = 0; i < str.length; i++) {
        fprintf(out, "%c", str.data[i]);
    }
}

bool String_Compare(String* a, String* b) 
{
    if (a->length != b->length) {
        return false;
    } else {
        for (int i = 0; i < a->length; i++) {
            if (a->data[i] != b->data[i]) 
            {
                return false;
            }
        }
    }
    return true;
}