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
#   - Still have to order class definitions (may be a lang server thing)
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
        return text + f'</h{self.size}>\n'

class Paragraph(MarkdownNode):
    def __init__(self, children):
        self.children = children
    
    def __str__(self):
        text = '<p>'
        for child in self.children:
            text += str(child)
        return text + '</p>\n\n'

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
        return text + '</strong>'

class Italic(MarkdownNode):
    def __init__(self, children):
        self.children = children
    
    def __str__(self):
        text = '<em>'
        for child in self.children:
            text += str(child)
        return text + '</em>'

class Code(MarkdownNode):
    def __init__(self, text):
        self.text = text
    
    def __str__(self):
        return f'<code>{self.text}</code>'

class Link(MarkdownNode):
    def __init__(self, text, url):
        self.text = text
        self.url = url
    
    def __str__(self):
        return f'<a href=\'{self.url}\'>{self.text}</a>'


class Token:
    def __init__(self, data, line, col):
        self.data = data
        self.line = line
        self.col = col

tokens = []
index = 0

def init_parser(contents:str):
    data = contents[0]
    line = 1
    col = 1
    old_col = 1
    old_c = data
    for c in contents[1:]:
        if old_c in '\n\r' or ((old_c in '_*`#[]()!') != (c in '_*`#[]()!')) or c in '#[(!\n\r':
            tokens.append(Token(data, line, old_col))
            old_col = col + 1
            if c == '\n':
                line += 1
                col = 0
            data = ''
        if old_c != '#' or not c.isspace():
            data += c
        col += 1
        old_c = c
    tokens.append(Token(data, line, col))
    tokens.append(Token('\n', line, col))


def pop():
    global index
    index += 1
    return tokens[index - 1]

def peek():
    return tokens[index]
    
def accept(data):
    if tokens[index].data == data:
        return pop().data
    else:
        return None

def expect(data):
    if accept(data) == None:
        top = peek()
        print(f'error: {top.line}:{top.col} expected `{data}` got `{top.data if top.data[0] in "_*`#[]()!" else "text"}`')
        sys.exit(1)

def take_until(sentinel):
    text = ''
    while not accept(sentinel):
        text += pop().data
    return text

def parse_document():
    while index < len(tokens) - 1:
        node = parse_node()
        if node:
            yield node

def parse_node():
    if accept('#'):
        return parse_header()
    elif accept('```'):
        return parse_code_block()
    elif accept('!'):
        return parse_image()
    elif accept('\n'):
        return None
    else:
        return parse_paragraph()

def parse_header():
    size = 1
    while accept('#'):
        size += 1
    return Header(size, parse_formatted_text({'\n'}))

def parse_paragraph():
    return Paragraph(parse_formatted_text({'\n'}))

def parse_code_block():
    return Code(take_until('```'))

def parse_image():
    expect('[')
    text = pop().data
    expect(']')
    expect('(')
    url = pop().data
    expect(')')
    return Image(text, url)

def parse_formatted_text(bounds):
    retval = []
    while not peek().data in bounds:
        if accept('_') or accept('*'):
            retval.append(parse_italic(bounds))
        elif accept('__') or accept('**'):
            retval.append(parse_bold(bounds))
        elif accept('`'):
            retval.append(parse_code())
        elif accept('['):
            retval.append(parse_link())
        else:
            retval.append(Text(pop().data))
    return retval

def parse_italic(bounds):
    children = parse_formatted_text(bounds.union({'*', '_'}))
    if not accept('*'):
        expect('_')
    return Italic(children)

def parse_bold(bounds):
    children = parse_formatted_text(bounds.union({'**', '__'}))
    if not accept('**'):
        expect('__')
    return Bold(children)

def parse_code():
    return Code(take_until('`'))

def parse_link():
    text = pop().data
    expect(']')
    expect('(')
    url = pop().data
    expect(')')
    return Link(text, url)


# Open input file, read contents
with open(sys.argv[1]) as f:
    contents = f.read()

# Create parser, parse Markdown document
init_parser(contents)

# Open output file, write HTML document
with open('output.html', 'w') as f:
    for node in parse_document():
        f.write(str(node))