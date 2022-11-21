#include <string>
#include <sstream>
#include "node.hpp"

std::string Header::getString() {
    std::ostringstream ss;
    ss << "<h" << this->size << ">";
    for (Node* node : this->children) {
        ss << node->getString();
    }
    ss << "</h" << this->size << ">";
    return ss.str();
}

std::string Paragraph::getString() {
    std::ostringstream ss;
    ss << "<p>";
    for (Node* node : this->children) {
        ss << node->getString();
    }
    ss << "</p>";
    return ss.str();
}

std::string CodeBlock::getString() {
    std::ostringstream ss;
    ss << "<pre><code>" << this->text << "</pre></code>";
    return ss.str();
}

std::string Image::getString() {
    std::ostringstream ss;
    ss << "<img src=\"" << this->url << "\" alt=\"" << this->text << "\" />";
    return ss.str();
}

std::string Text::getString() {
    return this->text;
}

std::string Italic::getString() {
    std::ostringstream ss;
    ss << "<em>";
    for (Node* node : this->children) {
        ss << node->getString();
    }
    ss << "</em>";
    return ss.str();
}

std::string Bold::getString() {
    std::ostringstream ss;
    ss << "<strong>";
    for (Node* node : this->children) {
        ss << node->getString();
    }
    ss << "</strong>";
    return ss.str();
}

std::string Code::getString() {
    std::ostringstream ss;
    ss << "<code>" << this->text << "</code>";
    return ss.str();
}

std::string Link::getString() {
    std::ostringstream ss;
    ss << "<a href=\"" << this->url << "\">" << this->text << "</a>";
    return ss.str();
}
