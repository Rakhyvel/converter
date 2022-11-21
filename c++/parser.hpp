#pragma once
#include <iostream>
#include <string>
#include <set>
#include <vector>
#include "node.hpp"

bool isSpecialChar(char c);

struct Token {
    std::string data;
    int line;
    int col;
};

class Parser {
public:
    Parser(std::string content) {
        this->index = 0;
        this->tokens = std::vector<Token*>();

        std::string data = "";
        data += content[0];
        int line = 1;
        int col = 1;
        int oldCol = 1;
        char oldC = content.at(0);
        for (int i = 1; i < content.length(); i ++) {
            char c = content.at(i);
            if (data[data.length() - 1] == '\n' || (isSpecialChar(data[data.length() - 1]) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n') {
                this->tokens.push_back(new Token{data, line, oldCol});
                oldCol = col + 1;
                if (data.find("\n") != std::string::npos) {
                    line += 1;
                    col = 0;
                }
                data = "";
            }
            if (oldC != '#' || !isspace(c)) {
                data.push_back(c);
                oldC = c;
            } else {
                oldC = c;
            }
            col += 1;
        }
        this->tokens.push_back(new Token{data, line, oldCol});
        this->tokens.push_back(new Token{"\n", line, oldCol});
    }

    std::vector<Node*> parseDocument();
    Node* parseNode();
    Header* parseHeader();
    Paragraph* parseParagraph();
    CodeBlock* parseCodeBlock();
    Image* parseImage();
    std::vector<Node*> parseFormattedText(std::set<std::string> bounds);
    Italic* parseItalic(std::set<std::string> bounds);
    Bold* parseBold(std::set<std::string> bounds);
    Code* parseCode();
    Link* parseLink();
    
private:
    Token* pop();
    Token* peek();
    Token* accept(std::string data);
    Token* expect(std::string data);

    std::vector<Token*> tokens;
    int index;
};