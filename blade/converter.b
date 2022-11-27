# To run: blade converter.b ../input.md
# Pros:
#   - Good file IO
#   - Great documentation and tutorial
#   - Good standard library
# Cons:
#   - Dynamically typed
#   - Lang server could use some work
#   - Not statically checked for correctness, have to run it to test if it works

import os

def is_special_char(c) {
    return c == '_' or
        c == '*' or
        c == '`' or
        c == '#' or
        c == '[' or
        c == ']' or
        c == '(' or
        c == ')' or
        c == '!'
}

class Node {
    get_HTML() {return "should not be called"}
}

class Header < Node {
    var size = 0
    var children = []

    Header(size, children) {
        self.size = size
        self.children = children
    }

    get_HTML() {
        return "<h${self.size}>${get_HTML_from_nodes(self.children)}</h${self.size}>\n"
    }
}

class Paragraph < Node {
    var children = []

    Paragraph(children) {
        self.children = children
    }

    get_HTML() {
        return "<p>${get_HTML_from_nodes(self.children)}</p>\n\n"
    }
}

class CodeBlock < Node {
    var text = ""

    CodeBlock(text) {
        self.text = text
    }

    get_HTML() {
        return "<pre><code>${self.text}</code></pre>\n\n"
    }
}

class Image < Node {
    var text = ""
    var url = ""

    Image(text, url) {
        self.text = text
        self.url = url
    }

    get_HTML() {
        return "<img src=\"${self.url}\" alt=\"${self.text}\" />"
    }
}

class Text < Node {
    var text

    Text(text) {
        self.text = text
    }

    get_HTML() {
        return self.text
    }
}

class Italic < Node {
    var children = []

    Italic(children) {
        self.children = children
    }

    get_HTML() {
        return "<em>${get_HTML_from_nodes(self.children)}</em>"
    }
}

class Bold < Node {
    var children = []

    Bold(children) {
        self.children = children
    }

    get_HTML() {
        return "<strong>${get_HTML_from_nodes(self.children)}</strong>"
    }
}

class Code < Node {
    var text = ""

    Code(text) {
        self.text = text
    }

    get_HTML() {
        return "<code>${self.text}</code>"
    }
}

class Link < Node {
    var text = ""
    var url = ""

    Link(text, url) {
        self.text = text
        self.url = url
    }

    get_HTML() {
        return "<a href=\"${self.url}\">${self.text}</a>"
    }
}

def get_HTML_from_nodes(nodes) {
    var output = ""
    for node in nodes {
        output += node.get_HTML()
    }
    return output
}

class Token {
    var data = ""
    var line = 0
    var col = 0
    Token(data, line, col) {
        self.data = data
        self.line = line
        self.col = col
    }
}

class Parser {
    var tokens = []
    var index = 0

    Parser(contents) {
        var data = contents[0]
        var line = 1
        var col = 1
        var oldCol = 1
        var oldC = contents[0]
        for c in contents[1,] {
            if oldC == '\n' or oldC == '\r' or (is_special_char(oldC) != is_special_char(c)) or c == '#' or c == '[' or c == '(' or c == '!' or c == '\n' or c == '\r' {
                if !data.match('/.*\r.*/') {
                    self.tokens.append(Token(data, line, oldCol))
                }
                oldCol = col + 1
                if c == '\n' {
                    line++
                    col = 0
                }
                data = ''
            }
            if oldC != '#' or !c.is_space() {
                data += c
            }
            col++
            oldC = c
        }
        self.tokens.append(Token(data, line, oldCol))
        self.tokens.append(Token('\n', line, oldCol))
    }

    pop() {
        self.index++
        return self.tokens[self.index - 1]
    }

    peek() {
        return self.tokens[self.index]
    }

    accept(data) {
        if self.peek().data == data {
            return self.pop()
        } else {
            return nil
        }
    }

    expect(data) {
        if self.accept(data) == nil {
            var top = self.peek()
            if is_special_char(top.data[0]) {
                echo 'error: ${top.line}:${top.col} expected `${data}`, got `${top.data}`'
            } else {
                echo 'error: ${top.line}:${top.col} expected `${data}`, got text'
            }
            os.exit(1)
        }
    }

    take_until(sentinel) {
        var retval = ''
        while self.accept(sentinel) == nil {
            retval += self.pop().data
        }
        return retval
    }

    parse_document() {
        var retval = []
        while self.index < self.tokens.length() - 1 {
            var node = self.parse_node()
            if node != nil {
                retval.append(node)
            }
        }
        return retval
    }

    parse_node() {
        if self.accept('#') != nil {
            return self.parse_header()
        } else if self.accept('```') != nil {
            return self.parse_code_block()
        } else if self.accept('!') != nil {
            return self.parse_image()
        } else if self.accept('\n') == nil {
            return self.parse_paragraph()
        } else {
            return nil
        }
    }

    parse_header() {
        var size = 1
        while self.accept('#') != nil {
            size++
        }
        return Header(size, self.parse_formatted_text(['\n']))
    }

    parse_paragraph() {
        return Paragraph(self.parse_formatted_text(['\n']))
    }

    parse_code_block() {
        return CodeBlock(self.take_until('```'))
    }

    parse_image() {
        self.expect('[')
        var text = self.pop().data
        self.expect(']')
        self.expect('(')
        var url = self.pop().data
        self.expect(')')
        return Image(text, url)
    }

    parse_formatted_text(bounds) {
        var retval = []
        while !bounds.contains(self.peek().data) {
            if self.accept('_') != nil or self.accept('*') != nil {
                retval.append(self.parse_italic(bounds))
            } else if self.accept('__') != nil or self.accept('**') != nil {
                retval.append(self.parse_bold(bounds))
            } else if self.accept('`') != nil {
                retval.append(self.parse_code())
            } else if self.accept('[') != nil {
                retval.append(self.parse_link())
            } else {
                retval.append(Text(self.pop().data))
            }
        }
        return retval
    }

    parse_italic(bounds) {
        var newBounds = bounds.clone()
        newBounds.append('*')
        newBounds.append('_')
        var children = self.parse_formatted_text(newBounds)
        if self.accept('*') == nil {
            self.expect('_')
        }
        return Italic(children)
    }

    parse_bold(bounds) {
        var newBounds = bounds.clone()
        newBounds.append('**')
        newBounds.append('__')
        var children = self.parse_formatted_text(newBounds)
        if self.accept('**') == nil {
            self.expect('__')
        }
        return Bold(children)
    }

    parse_code() {
        return Code(self.take_until('`'))
    }

    parse_link() {
        var text = self.pop().data
        self.expect(']')
        self.expect('(')
        var url = self.pop().data
        self.expect(')')
        return Link(text, url)
    }
}

if os.args.length() != 3 {
    echo 'usage: blade converter.b <markdown-filename>'
} else {
    file("output.html", "w").write(get_HTML_from_nodes(Parser(file(os.args[2]).read()).parse_document()))
}