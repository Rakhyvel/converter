#pragma once
#include <string>
#include <vector>

class Node {
public:
    virtual std::string getString() = 0;
};


class Header: public Node {
public:
    Header(int size, std::vector<Node*> children) {
        this->size = size;
        this->children = children;
    }
    ~Header() {}
    virtual std::string getString();

private:
    int size;
    std::vector<Node*> children;
};


class Paragraph: public Node {
public:
    Paragraph(std::vector<Node*> children) {
        this->children = children;
    }
    ~Paragraph() {}
    virtual std::string getString();

private:
    std::vector<Node*> children;
};


class CodeBlock: public Node {
public:
    CodeBlock(std::string text) {
        this->text = text;
    }
    ~CodeBlock() {}
    virtual std::string getString();

private:
    std::string text;
};


class Image: public Node {
public:
    Image(std::string text, std::string url) {
        this->text = text;
        this->url = url;
    }
    ~Image() {}
    virtual std::string getString();

private:
    std::string text;
    std::string url;
};


class Text: public Node {
public:
    Text(std::string text) {
        this->text = text;
    }
    ~Text() {}
    virtual std::string getString();

private:
    std::string text;
};


class Italic: public Node {
public:
    Italic(std::vector<Node*> children) {
        this->children = children;
    }
    ~Italic() {}
    virtual std::string getString();

private:
    std::vector<Node*> children;
};


class Bold: public Node {
public:
    Bold(std::vector<Node*> children) {
        this->children = children;
    }
    ~Bold() {}
    virtual std::string getString();

private:
    std::vector<Node*> children;
};


class Code: public Node {
public:
    Code(std::string text) {
        this->text = text;
    }
    ~Code() {}
    virtual std::string getString();

private:
    std::string text;
};


class Link: public Node {
public:
    Link(std::string text, std::string url) {
        this->text = text;
        this->url = url;
    }
    ~Link() {}
    virtual std::string getString();

private:
    std::string text;
    std::string url;
};