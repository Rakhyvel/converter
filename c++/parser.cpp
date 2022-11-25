#include "node.hpp"
#include "parser.hpp"

bool isSpecialChar(char c) {
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

Token* Parser::pop() {
    index += 1;
    if (index >= tokens.size() - 1) {
        return nullptr;
    } else {
        return tokens.at(index - 1);
    }
}

Token* Parser::peek() {
    if (index >= tokens.size() - 1) {
        return nullptr;
    } else {
        return tokens.at(index);
    }
}

Token* Parser::accept(std::string data) {
    if (peek()->data == data) {
        return pop();
    } else {
        return nullptr;
    }
}

void Parser::expect(std::string data) {
    if (!accept(data)) {
        Token* top = peek();
        if (isSpecialChar(top->data.at(0))) {
            std::cerr << "error: " << top->line << ":" << top->col << " expected `" << data << "`, got " << top->data << std::endl;
        } else {
            std::cerr << "error: " << top->line << ":" << top->col << " expected `" << data << "`, got text" << std::endl;
        }
        exit(1);
    }
}

std::vector<Node*> Parser::parseDocument() {
    std::vector<Node*> retval;
    while (index < tokens.size() - 1) {
        Node* node = parseNode();
        if(node) {
            retval.push_back(node);
        }
    }
    return retval;
}

Node* Parser::parseNode() {
    if (accept("#")) {
        return parseHeader();
    } else if (accept("```")) {
        return parseCodeBlock();
    } else if (accept("!")) {
        return parseImage();
    } else if (accept("\n")) {
        return nullptr;
    } else {
        return parseParagraph();
    }
}

Header* Parser::parseHeader() {
    int size = 1;
    while (accept("#")) {
        size++;
    }
    std::set<std::string> bounds = {"\n"};
    return new Header{size, parseFormattedText(bounds)};
}

Paragraph* Parser::parseParagraph() {
    std::set<std::string> bounds = {"\n"};
    return new Paragraph{parseFormattedText(bounds)};
}

CodeBlock* Parser::parseCodeBlock() {
    std::string text = "";
    while (!accept("```")) {
        text += pop()->data;
    }
    return new CodeBlock{text};
}

Image* Parser::parseImage() {
    expect("[");
    std::string text = pop()->data;
    expect("]");
    expect("(");
    std::string url = pop()->data;
    expect(")");
    return new Image{text, url};
}

std::vector<Node*> Parser::parseFormattedText(std::set<std::string> bounds) {
    std::vector<Node*> retval;

    while (bounds.find(peek()->data) == bounds.end()) { // While bounds does not contain the front of the token queue
        if (accept("_") || accept("*")) {
            retval.push_back(parseItalic(bounds));
        } else if (accept("__") || accept("**")) {
            retval.push_back(parseBold(bounds));
        } else if (accept("`")) {
            retval.push_back(parseCode());
        } else if (accept("[")) {
            retval.push_back(parseLink());
        } else {
            retval.push_back(new Text{pop()->data});
        }
    }
    return retval;
}

Italic* Parser::parseItalic(std::set<std::string> bounds) {
    std::set<std::string> newBounds = bounds;
    newBounds.insert("*");
    newBounds.insert("_");
    std::vector<Node*> children = parseFormattedText(newBounds);
    if (!accept("*")) {
        expect("_");
    }
    return new Italic{children};
}

Bold* Parser::parseBold(std::set<std::string> bounds) {
    std::set<std::string> newBounds = bounds;
    newBounds.insert("**");
    newBounds.insert("__");
    std::vector<Node*> children = parseFormattedText(newBounds);
    if (!accept("**")) {
        expect("__");
    }
    return new Bold{children};
}

Code* Parser::parseCode() {
    std::string text = "";
    while (!accept("`")) {
        text += pop()->data;
    }
    return new Code{text};
}

Link* Parser::parseLink() {
    std::string text = pop()->data;
    expect("]");
    expect("(");
    std::string url = pop()->data;
    expect(")");
    return new Link(text, url);
}