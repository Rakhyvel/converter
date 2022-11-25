// To run: gcc converter.c list.c node.c parser.c string.c token.c -o converter.exe && converter.exe ../input.md
// Pros:
//  - Fast
//  - No garbage collector
// Cons:
//  - Header files
//  - No data structures in standard library
//  - No easy way to just do command line run a program
//  - Arrays don't have length associated with them
//  - Semicolons, parens around if/while/for
//  - Stupid way to do file input/output
//  - No generics
//  - Horrible string manipulation
//  - No default arguments
//  - No way to do error handling
//  - No boolean type
//  - Unknown symbols are infered to be external, rather than an actual error
//  - Have to order declarations
//  - Different operator to dereference a struct field access
//  - Stupid function pointer syntax
//  - No error if you forget to give a parameter to a function
//  - No namespacing
//  - Impossible to debug
//  - Weakly typed

#include "node.h"
#include "parser.h"
#include "string.h"
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv)
{
    if (argc != 2) 
    {
        fprintf(stderr, "usage: converter.exe <markdown-filename>\n");
        system("pause");
    } 
    else 
    {
        // Open input file
        FILE* input = fopen(argv[1], "r");
        if (!input) 
        {
            fprintf(stderr, "error opening input file");
            exit(1);
        }

        // Read into a string
        String contents = String_New();
        int nextChar;
        while ((nextChar = fgetc(input)) != EOF) 
        {
            String_Append(&contents, nextChar);
        }
        fclose(input);

        Parser_Init(contents);
        List* document = Parser_ParseDocument();

        // Write out document
        FILE* output = fopen("output.html", "w");
        if (!input) 
        {
            fprintf(stderr, "error opening output file");
            exit(1);
        }
        forall (elem, document)
        {
            Node_WriteHTML(output, elem->data);
        }
        fclose(output);
    }
}