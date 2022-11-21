// To run: g++ converter.cpp parser.cpp node.cpp -o converter.exe && converter.exe ../input.md
// Pros:
//  - Concept of streams built into language
//  - Length is a member of strings/vectors
//  - std::optional<T> data type (in C++17, which my compiler didn't support so I couldn't use it)
//  - `let` type inference (could use a better syntax though)
//  - foreach
// Cons:
//  - Semi colons, especially after things like structs and classes
//  - ifstream returns an empty string if a file doesn't exist, rather than properly reporting an error
//  - Arrays have no length information (inherited from C)
//  - Header files. (better in C++ than in C, but still embarrasing in a modern programming language)
//  - Compile errors that have to do with templates are obtuse and basically useless
//  - NULL VALUES! And no gaurantee about unwrapping them (C++17 optional<T> fixes this)
//  - Using streams is a clunky way to do string concat and formatting. Would prefer a C-style sprintf way
//  - Need parens around if, while, for conditions
//  - Explicit dereference dot operator
//  - std::string has length() method, but std::vector has size() method
//  - Lots of boilerplate for classes and methods
//  - Confusing vtable model, especially for abstract classes
//  - Iterator model works well for iterating, BUT it feels like a bit of a leap to use iterators to check if a container contains something
//  - Runtime errors don't have source code position info (probably for security, or size. should be a debug option at least)
//  - Exceptions can return from any function, no warning, no expectation to handle them, program doesn't crash, just silently exits. Awful!

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include "node.hpp"
#include "parser.hpp"

auto main(int argc, char** argv)->int {
    if (argc != 2) {
        std::cerr << "usage: converter.exe <filename>" << std::endl;
        return 1;
    } else {
        // Read contents into a big ole string
        std::ifstream ifs(argv[1]);
        std::string content;
        content.assign( (std::istreambuf_iterator<char>(ifs) ),
                        (std::istreambuf_iterator<char>()    ) );

        Parser parser = Parser(content);
        std::vector<Node*> nodes = parser.parseDocument();

        std::fstream out;
        out.open("output.html", std::ios::out);
        if (!out) {
            std::cerr << "error writing output file" << std::endl;
        } else {
            for (Node* node : nodes) {
                out << node->getString() << std::endl;
            }
        }

        return 0;
    }
}