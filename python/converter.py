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
#   - Indentation makes it hard to read sometimes, hard to hold onto "landmarks"


import sys


class MarkdownNode:
    pass

class Header(MarkdownNode):
    def __init__(self, size:int, children:list[MarkdownNode]):
        self.size = size
        self.children = children
    
    def __str__(self):
        text = f"<h{self.size}>"
        for i, child in enumerate(self.children):
            if i == 0:
                text += str(child).lstrip()
            else:
                text += str(child)
        text += f"</h{self.size}>\n"
        return text

class Paragraph(MarkdownNode):
    def __init__(self, children:list[MarkdownNode]):
        self.children = children
    
    def __str__(self):
        text = f"<p>"
        for child in self.children:
            text += str(child)
        text += f"</p>\n"
        return text

class CodeBlock(MarkdownNode):
    def __init__(self, text:str):
        self.text = text
    
    def __str__(self):
        return f"<pre><code>{self.text}</code></pre>\n"

class Image(MarkdownNode):
    def __init__(self, text:str, url:str):
        self.text = text
        self.url = url
    
    def __str__(self):
        return f"<img src=\"{self.url}\" alt=\"{self.text}\" />\n"

class Text(MarkdownNode):
    def __init__(self, text:str):
        self.text = text
    
    def __str__(self):
        return self.text

class Bold(MarkdownNode):
    def __init__(self, children:list[MarkdownNode]):
        self.children = children
    
    def __str__(self):
        text = "<strong>"
        for child in self.children:
            text += str(child)
        text += "</strong>"
        return text

class Italic(MarkdownNode):
    def __init__(self, children:list[MarkdownNode]):
        self.children = children
    
    def __str__(self):
        text = "<em>"
        for child in self.children:
            text += str(child)
        text += "</em>"
        return text

class Code(MarkdownNode):
    def __init__(self, text:str):
        self.text = text
    
    def __str__(self):
        text = f"<code>{self.text}</code>"
        return text

class Link(MarkdownNode):
    def __init__(self, text:str, url:str):
        self.text = text
        self.url = url
    
    def __str__(self):
        text = f"<a href=\"{self.url}\">{self.text}</a>"
        return text


class Parser:
    def __init__(self, tokens:list[str]):
        self.tokens = tokens
        self.index = 0

    def pop(self)->str:
        self.index += 1
        return self.tokens[self.index - 1]
        
    def accept(self, token:str)->str|None:
        if self.tokens[self.index] == token:
            return self.pop()
        else:
            return None

    def parse_document(self)->list[MarkdownNode]:
        retval = []
        while self.index < len(self.tokens) - 1:
            node = self.parse_node()
            if node:
                retval.append(node) 
        return retval

    def parse_node(self)->MarkdownNode|None:
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

    def parse_header(self)->Header:
        size = 1
        while self.accept('#'):
            size += 1
        return Header(size, self.parse_many_formatted_text({'\n'}))

    def parse_code_block(self)->CodeBlock:
        text = ""
        while not self.accept('```'):
            text += self.pop()
        return CodeBlock(text)

    def parse_image(self)->Image:
        self.accept('[')
        text = self.pop()
        self.accept(']')
        self.accept('(')
        url = self.pop()
        self.accept(')')
        return Image(text, url)

    def parse_paragraph(self)->Paragraph:
        return Paragraph(self.parse_many_formatted_text({'\n'}))

    def parse_many_formatted_text(self, bounds:set[str])->list[MarkdownNode]:
        children = []
        while True:
            next = self.parse_formatted_text(bounds)
            if len(next) == 0:
                break
            else:
                children += next
        return children

    def parse_formatted_text(self, bounds:set[str])->list[MarkdownNode]:
        retval = []
        if self.tokens[self.index] in bounds:
            return []
        elif self.accept('_') or self.accept('*'):
            retval.append(self.parse_italic(bounds))
        elif self.accept('__') or self.accept('**'):
            retval.append(self.parse_bold(bounds))
        elif self.accept('`'):
            retval.append(self.parse_code())
        elif self.accept('['):
            retval.append(self.parse_link())
        else:
            retval.append(Text(self.pop()))
        return retval

    def parse_italic(self, bounds:set[str])->Italic:
        children = self.parse_many_formatted_text(bounds.union({'*', '_', '\n'}))
        if not self.accept('*'):
            self.accept('_')
        return Italic(children)

    def parse_bold(self, bounds:set[str])->Bold:
        children = self.parse_many_formatted_text(bounds.union({'**', '__', '\n'}))
        if not self.accept('**'):
            self.accept('__')
        return Bold(children)

    def parse_code(self)->Code:
        text = ""
        while not self.accept('`'):
            text += self.pop()
        return Code(text)

    def parse_link(self)->Link:
        text = self.pop()
        self.accept(']')
        self.accept('(')
        url = self.pop()
        self.accept(')')
        return Link(text, url)


def scanner(line:str)->list[str]:
    retval = []
    token = line[0]
    specialChars = {'_', '*', '`', '#', '[', ']', '(', ')', '!'}
    for c in line[1:]:
        if c == '\n':
            break
        elif ((token[-1] in specialChars) != (c in specialChars)) or (c == '#' or c == '(' or c == '['):
            retval.append(token)
            token = c
        else:
            token += c
    retval.append(token)
    retval.append('\n')
    return retval


def main():
    with open(sys.argv[1], 'r') as f:
        lines = f.readlines()
    tokens = []
    for line in lines:
        tokens += scanner(line)
    parser = Parser(tokens)
    document = parser.parse_document()
    with open('python/output.html', 'w') as f:
        for node in document:
            f.write(str(node))


if __name__ == '__main__':
    main()