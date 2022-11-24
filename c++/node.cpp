#include <string>
#include <sstream>
#include "node.hpp"

std::string Header::getString() {
    std::ostringstream ss;
    ss << "<h" << size << ">";
    for (Node* node : children) {
        ss << node->getString();
    }
    ss << "</h" << size << ">";
    return ss.str();
}

std::string Paragraph::getString() {
    std::ostringstream ss;
    ss << "<p>";
    for (Node* node : children) {
        ss << node->getString();
    }
    ss << "</p>\n";
    return ss.str();
}

std::string CodeBlock::getString() {
    std::ostringstream ss;
    ss << "<pre><code>" << text << "</pre></code>\n";
    return ss.str();
}

std::string Image::getString() {
    std::ostringstream ss;
    ss << "<img src=\"" << url << "\" alt=\"" << text << "\" />\n";
    return ss.str();
}

std::string Text::getString() {
    return text;
}

std::string Italic::getString() {
    std::ostringstream ss;
    ss << "<em>";
    for (Node* node : children) {
        ss << node->getString();
    }
    ss << "</em>";
    return ss.str();
}

std::string Bold::getString() {
    std::ostringstream ss;
    ss << "<strong>";
    for (Node* node : children) {
        ss << node->getString();
    }
    ss << "</strong>";
    return ss.str();
}

std::string Code::getString() {
    std::ostringstream ss;
    ss << "<code>" << text << "</code>";
    return ss.str();
}

std::string Link::getString() {
    std::ostringstream ss;
    ss << "<a href=\"" << url << "\">" << text << "</a>";
    return ss.str();
}
