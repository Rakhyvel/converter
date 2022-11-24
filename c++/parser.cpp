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
        index += 1;
        return tokens.at(index - 1);
    } else {
        return nullptr;
    }
}

void Parser::expect(std::string data) {
    if (accept(data) == nullptr) {
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
        if(node != nullptr) {
            retval.push_back(node);
        }
    }
    return retval;
}

Node* Parser::parseNode() {
    if (accept("#") != nullptr) {
        return parseHeader();
    } else if (accept("```") != nullptr) {
        return parseCodeBlock();
    } else if (accept("!") != nullptr) {
        return parseImage();
    } else if (accept("\n") != nullptr) {
        return nullptr;
    } else {
        return parseParagraph();
    }
}

Header* Parser::parseHeader() {
    int size = 1;
    while (accept("#") != nullptr) {
        size += 1;
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
    while (accept("```") == nullptr) {
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
        if (accept("_") != nullptr || accept("*") != nullptr) {
            retval.push_back(parseItalic(bounds));
        } else if (accept("__") != nullptr || accept("**") != nullptr) {
            retval.push_back(parseBold(bounds));
        } else if (accept("`") != nullptr) {
            retval.push_back(parseCode());
        } else if (accept("[") != nullptr) {
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
    if (accept("*") == nullptr) {
        expect("_");
    }
    return new Italic{children};
}

Bold* Parser::parseBold(std::set<std::string> bounds) {
    std::set<std::string> newBounds = bounds;
    newBounds.insert("**");
    newBounds.insert("__");
    std::vector<Node*> children = parseFormattedText(newBounds);
    if (accept("**") == nullptr) {
        expect("__");
    }
    return new Bold{children};
}

Code* Parser::parseCode() {
    std::string text = "";
    while (accept("`") == nullptr) {
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