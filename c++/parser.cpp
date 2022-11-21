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
    this->index += 1;
    if (this->index >= this->tokens.size() - 1) {
        return nullptr;
    } else {
        return this->tokens.at(this->index - 1);
    }
}

Token* Parser::peek() {
    if (this->index >= this->tokens.size() - 1) {
        return nullptr;
    } else {
        return this->tokens.at(this->index);
    }
}

Token* Parser::accept(std::string data) {
    if (this->index >= this->tokens.size() - 1) {
        return nullptr;
    } else if (this->tokens.at(this->index)->data == data) {
        this->index += 1;
        return this->tokens.at(this->index - 1);
    } else {
        return nullptr;
    }
}

Token* Parser::expect(std::string data) {
    Token* res = this->accept(data);
    if (res == nullptr) {
        Token* top = this->peek();
        if (isSpecialChar(top->data.at(0))) {
            std::cerr << "error: " << top->line << ":" << top->col << " expected `" << data << "`, got " << top->data << std::endl;
        } else {
            std::cerr << "error: " << top->line << ":" << top->col << " expected `" << data << "`, got text" << std::endl;
        }
        exit(1);
        return nullptr;
    } else {
        return res;
    }
}

std::vector<Node*> Parser::parseDocument() {
    std::vector<Node*> retval;
    while (this->index < this->tokens.size() - 1) {
        Node* node = this->parseNode();
        if(node != nullptr) {
            retval.push_back(node);
        }
    }
    return retval;
}

Node* Parser::parseNode() {
    if (this->accept("#") != nullptr) {
        return this->parseHeader();
    } else if (this->accept("```") != nullptr) {
        return this->parseCodeBlock();
    } else if (this->accept("!") != nullptr) {
        return this->parseImage();
    } else if (this->accept("\n") != nullptr) {
        return nullptr;
    } else {
        return this->parseParagraph();
    }
}

Header* Parser::parseHeader() {
    int size = 1;
    while (this->accept("#") != nullptr) {
        size += 1;
    }
    std::set<std::string> bounds = {"\n"};
    return new Header{size, this->parseFormattedText(bounds)};
}

Paragraph* Parser::parseParagraph() {
    std::set<std::string> bounds = {"\n"};
    return new Paragraph{this->parseFormattedText(bounds)};
}

CodeBlock* Parser::parseCodeBlock() {
    std::string text = "";
    while (this->accept("```") == nullptr) {
        text += this->pop()->data;
    }
    return new CodeBlock{text};
}

Image* Parser::parseImage() {
    this->expect("[");
    std::string text = this->pop()->data;
    this->expect("]");
    this->expect("(");
    std::string url = this->pop()->data;
    this->expect(")");
    return new Image{text, url};
}

std::vector<Node*> Parser::parseFormattedText(std::set<std::string> bounds) {
    std::vector<Node*> retval;

    while (bounds.find(this->peek()->data) == bounds.end()) { // While bounds does not contain the front of the token queue
        if (this->accept("_") != nullptr || this->accept("*") != nullptr) {
            retval.push_back(this->parseItalic(bounds));
        } else if (this->accept("__") != nullptr || this->accept("**") != nullptr) {
            retval.push_back(this->parseBold(bounds));
        } else if (this->accept("`") != nullptr) {
            retval.push_back(this->parseCode());
        } else if (this->accept("[") != nullptr) {
            retval.push_back(this->parseLink());
        } else {
            retval.push_back(new Text{this->pop()->data});
        }
    }
    return retval;
}

Italic* Parser::parseItalic(std::set<std::string> bounds) {
    std::set<std::string> newBounds = bounds;
    newBounds.insert("*");
    newBounds.insert("_");
    std::vector<Node*> children = this->parseFormattedText(newBounds);
    if (this->accept("*") == nullptr) {
        this->expect("_");
    }
    return new Italic{children};
}

Bold* Parser::parseBold(std::set<std::string> bounds) {
    std::set<std::string> newBounds = bounds;
    newBounds.insert("**");
    newBounds.insert("__");
    std::vector<Node*> children = this->parseFormattedText(newBounds);
    if (this->accept("**") == nullptr) {
        this->expect("__");
    }
    return new Bold{children};
}

Code* Parser::parseCode() {
    std::string text = "";
    while (this->accept("`") == nullptr) {
        text += this->pop()->data;
    }
    return new Code{text};
}

Link* Parser::parseLink() {
    std::string text = this->pop()->data;
    this->expect("]");
    this->expect("(");
    std::string url = this->pop()->data;
    this->expect(")");
    return new Link(text, url);
}