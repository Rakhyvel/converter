# To run: python converter.py ../input.md
# Pros:
#   - Can run/test program with one command
#   - Really good file IO and string support
#   - Modular indexing is helpful for getting the last element, no bounds checks required, may be confusing if unintentional though
#   - Being able to say 'elem in set' as a boolean is useful
#   - Sets in general have really good support, very easy, no cognition required
#   - Formatted strings!
# Cons:
#   - No implicit main function, have to do that stupid 'if __name__ == __main__' thing
#   - Can't leave a function body/if body/for body blank when filling out a function, which is sorta annoying
#   - Command line arguments are weird, because there's no implicit main function
#   - Inheritance is a little confusing, I prefer interfaces instead
#   - Dynamically typed
#   - Still have to order type definitions (may be a lang server thing)
#   - Indentation makes it hard to read sometimes, hard to hold onto 'landmarks'


import sys


class MarkdownNode:
    pass

class Header(MarkdownNode):
    def __init__(self, size, children):
        self.size = size
        self.children = children
    
    def __str__(self):
        text = f'<h{self.size}>'
        for i, child in enumerate(self.children):
            if i == 0:
                text += str(child).lstrip()
            else:
                text += str(child)
        text += f'</h{self.size}>\n'
        return text

class Paragraph(MarkdownNode):
    def __init__(self, children):
        self.children = children
    
    def __str__(self):
        text = f'<p>'
        for child in self.children:
            text += str(child)
        text += f'</p>\n\n'
        return text

class CodeBlock(MarkdownNode):
    def __init__(self, text):
        self.text = text
    
    def __str__(self):
        return f'<pre><code>{self.text}</code></pre>\n\n'

class Image(MarkdownNode):
    def __init__(self, text, url):
        self.text = text
        self.url = url
    
    def __str__(self):
        return f'<img src=\'{self.url}\' alt=\'{self.text}\' />\n\n'

class Text(MarkdownNode):
    def __init__(self, text):
        self.text = text
    
    def __str__(self):
        return self.text

class Bold(MarkdownNode):
    def __init__(self, children):
        self.children = children
    
    def __str__(self):
        text = '<strong>'
        for child in self.children:
            text += str(child)
        text += '</strong>'
        return text

class Italic(MarkdownNode):
    def __init__(self, children):
        self.children = children
    
    def __str__(self):
        text = '<em>'
        for child in self.children:
            text += str(child)
        text += '</em>'
        return text

class Code(MarkdownNode):
    def __init__(self, text):
        self.text = text
    
    def __str__(self):
        text = f'<code>{self.text}</code>'
        return text

class Link(MarkdownNode):
    def __init__(self, text, url):
        self.text = text
        self.url = url
    
    def __str__(self):
        text = f'<a href=\'{self.url}\'>{self.text}</a>'
        return text


class Token:
    def __init__(self, data, line, pos):
        self.data = data
        self.line = line
        self.pos = pos

class Parser:
    def __init__(self, contents:str):
        self._tokens = []
        self._index = 0

        data = contents[0]
        line = 1
        col = 1
        old_col = 1
        old_c = contents[0]
        for c in contents[1:]:
            if old_c in {'\n', '\r'} or ((old_c in '_*`#[]()!') != (c in '_*`#[]()!')) or c in '#[(!\n\r':
                if '\r' not in data:
                    print(data)
                    self._tokens.append(Token(data, line, old_col))
                old_col = col + 1
                if c == '\n':
                    line += 1
                    col = 0
                data = ''
            if old_c != '#' or not c.isspace():
                data += c
            col += 1
            old_c = c
        self._tokens.append(Token(data, line, col))
        self._tokens.append(Token('\n', line, col))

    def pop(self):
        self._index += 1
        return self._tokens[self._index - 1]

    def peek(self):
        return self._tokens[self._index]
        
    def accept(self, data):
        if self._tokens[self._index].data == data:
            return self.pop().data
        else:
            return None

    def expect(self, data):
        if self.accept(data) == None:
            top = self.peek()
            if top.data[0] in '_*`#[]()!':
                print(f'error: {top.line}:{top.col} expected `{data}` got {top.data}')
            else:
                print(f'error: {top.line}:{top.col} expected `{data}` got text')

    def parse_document(self):
        retval = []
        while self._index < len(self._tokens) - 1:
            node = self.parse_node()
            if node:
                retval.append(node) 
        return retval

    def parse_node(self):
        if self.accept('#'):
            return self.parse_header()
        elif self.accept('```'):
            return self.parse_code_block()
        elif self.accept('!'):
            return self.parse_image()
        elif self.accept('\n'):
            return None
        else:
            return self.parse_paragraph()

    def parse_header(self):
        size = 1
        while self.accept('#'):
            size += 1
        return Header(size, self.parse_formatted_text({'\n'}))

    def parse_paragraph(self):
        return Paragraph(self.parse_formatted_text({'\n'}))

    def parse_code_block(self):
        text = ''
        while not self.accept('```'):
            text += self.pop().data
        return CodeBlock(text)

    def parse_image(self):
        self.expect('[')
        text = self.pop().data
        self.expect(']')
        self.expect('(')
        url = self.pop().data
        self.expect(')')
        return Image(text, url)

    def parse_formatted_text(self, bounds):
        retval = []
        while not self.peek().data in bounds:
            if self.accept('_') or self.accept('*'):
                retval.append(self.parse_italic(bounds))
            elif self.accept('__') or self.accept('**'):
                retval.append(self.parse_bold(bounds))
            elif self.accept('`'):
                retval.append(self.parse_code())
            elif self.accept('['):
                retval.append(self.parse_link())
            else:
                retval.append(Text(self.pop().data))
        return retval

    def parse_italic(self, bounds):
        children = self.parse_formatted_text(bounds.union({'*', '_'}))
        if not self.accept('*'):
            self.expect('_')
        return Italic(children)

    def parse_bold(self, bounds):
        children = self.parse_formatted_text(bounds.union({'**', '__'}))
        if not self.accept('**'):
            self.expect('__')
        return Bold(children)

    def parse_code(self):
        text = ''
        while not self.accept('`'):
            text += self.pop().data
        return Code(text)

    def parse_link(self):
        text = self.pop().data
        self.expect(']')
        self.expect('(')
        url = self.pop().data
        self.expect(')')
        return Link(text, url)


def main():
    # Open input file, read contents
    with open(sys.argv[1], 'r') as f:
        contents = f.read()

    # Create parser, parse Markdown document
    parser = Parser(contents)
    document = parser.parse_document()

    # Open output file, write HTML document
    with open('output.html', 'w') as f:
        for node in document:
            f.write(str(node))


if __name__ == '__main__':
    main()