# To run: nim compile --run converter.nim -- ../input.md
# Pros:
#   - Pretty terse and simple
#   - Strings are fairly easy
#   - I like the UFCS style of OOP, its honestly not too bad!
#   - Immutability
#   - Function body is result
#   - Generics work fairly well
#   - Able to chain `type` and probably `let`, `var`, `const`s, pretty neat!
#   - Structs initializers are good
# Cons:
#   - Weird data model, with sequences and stuff, but no access to lower level stuff
#   - Have to define procs in order. Maybe just a lang-server thing?
#   - Identifiers are just undefined if theyre not defined. Id rather have an error, when is that behavior ever desired?
#   - Overloading causes strange error messages, like in C++
#   - Have to import options, instead of them just being there
import os
import std/options
import std/strformat

type
    Node = ref object of RootObj
    Header = ref object of Node
        size: int
        children: seq[Node]
    Paragraph = ref object of Node
        children: seq[Node]
    CodeBlock = ref object of Node
        text: string
    Image = ref object of Node
        text: string
        url: string
    Text = ref object of Node
        text: string
    Italic = ref object of Node
        children: seq[Node]
    Bold = ref object of Node
        children: seq[Node]
    Code = ref object of Node
        text: string
    Link = ref object of Node
        text: string
        url: string
    Token = object
        data: string
        line: int
        col: int
    Parser = object
        tokens: seq[Token]
        index: int

method get_HTML(node: Node): string {.base.} =
    quit "to override!"

method get_HTML(header: Header): string =
    var children_string = ""
    for child in header.children:
        children_string.add(child.get_HTML())
    fmt"<h{header.size}>{children_string}</h{header.size}>" & "\n\n"

method get_HTML(paragraph: Paragraph): string =
    var children_string = ""
    for child in paragraph.children:
        children_string.add(child.get_HTML())
    fmt"<p>{children_string}</p>" & "\n\n"

method get_HTML(code_block: CodeBlock): string = 
    fmt"<pre><code>{code_block.text}</code></pre>" & "\n\n"

method get_HTML(image: Image): string = 
    fmt"<img src='{image.url}' alt='{image.text}' />"

method get_HTML(text: Text): string = text.text

method get_HTML(italic: Italic): string =
    var children_string = ""
    for child in italic.children:
        children_string.add(child.get_HTML())
    fmt"<em>{children_string}</em>"

method get_HTML(bold: Bold): string =
    var children_string = ""
    for child in bold.children:
        children_string.add(child.get_HTML())
    fmt"<strong>{children_string}</strong>"

method get_HTML(code: Code): string = fmt"<code>{code.text}</code>"

method get_HTML(link: Link): string = 
    fmt"<a href='{link.url}'>{link.text}</a>"

proc is_special_char(c: char): bool = 
    c in @['_', '*', '`', '#', '[', ']', '(', ')', '!']

proc tokenize(parser: var Parser, contents: string) =
    var data = ""
    data.add(contents[0])
    var line = 1
    var col = 1
    var old_col = 1
    var old_c = contents[0]
    for c in contents[1 ..< len(contents)]:
        if old_c == '\n' or old_c == '\r' or (is_special_char(old_c) != is_special_char(c)) or c in @['#', '[', '(', '!', '\n', '\r']:
            parser.tokens.add(Token(data: data, line: line, col: old_col))
            old_col = col + 1
            if c == '\n':
                line += 1
                col = 0
            data = ""
        if old_c != '#' or not (c in @[' ', '\t', '\n', '\r']):
            data.add(c)
        col += 1
        old_c = c
    parser.tokens.add(Token(data: data, line: line, col: col))
    parser.tokens.add(Token(data: "\n", line: line, col: col))

proc pop(parser: var Parser): Token =
    parser.index += 1
    parser.tokens[parser.index - 1]

proc peek(parser: var Parser): Token = parser.tokens[parser.index]

proc accept(parser: var Parser, data: string): Option[string] = 
    if parser.peek().data == data:
        some(parser.pop().data)
    else:
        none(string)

proc expect(parser: var Parser, data: string) =
    if parser.accept(data).isNone:
        var top = parser.peek()
        if is_special_char(top.data[0]):
            echo fmt"error: {top.line}:{top.col} expected `{data}` got `{top.data}`"
        else:
            echo fmt"error: {top.line}:{top.col} expected `{data}` text"
        system.quit 1
        
proc take_until(parser: var Parser, sentinel: string): string =
    var text = ""
    while parser.accept(sentinel).isNone:
        text = text & parser.pop().data
    text

proc parse_formatted_text(parser: var Parser, bounds: seq[string]): seq[Node]

proc parse_italic(parser: var Parser, bounds: seq[string]): Node =
    var new_bounds = newSeq[string](0)
    for bound in bounds:
        new_bounds.add(bound)
    new_bounds.add("*")
    new_bounds.add("_")
    var children = parser.parse_formatted_text(new_bounds)
    if parser.accept("*").isNone:
        parser.expect("_")
    return Italic(children: children)

proc parse_bold(parser: var Parser, bounds: seq[string]): Node =
    var new_bounds = newSeq[string](0)
    for bound in bounds:
        new_bounds.add(bound)
    new_bounds.add("**")
    new_bounds.add("__")
    var children = parser.parse_formatted_text(new_bounds)
    if parser.accept("**").isNone:
        parser.expect("__")
    return Bold(children: children)

proc parse_code(parser: var Parser): Node = Code(text: parser.take_until("`"))

proc parse_link(parser: var Parser): Node = 
    var text = parser.pop().data
    parser.expect("]")
    parser.expect("(")
    var url = parser.pop().data
    parser.expect(")")
    Link(text: text, url: url)

proc parse_formatted_text(parser: var Parser, bounds: seq[string]): seq[Node] =
    var retval = newSeq[Node](0)
    while parser.peek().data notin bounds:
        if parser.accept("_").isSome or parser.accept("*").isSome:
            retval.add(parser.parse_italic(bounds))
        elif parser.accept("__").isSome or parser.accept("**").isSome:
            retval.add(parser.parse_bold(bounds))
        elif parser.accept("`").isSome:
            retval.add(parser.parse_code())
        elif parser.accept("[").isSome:
            retval.add(parser.parse_link())
        else:
            retval.add(Text(text: parser.pop().data))
    return retval

proc parse_header(parser: var Parser): Node = 
    var size = 1
    while parser.accept("#").isSome:
        size += 1
    Header(size: size, children: parser.parse_formatted_text(@["\n"]))

proc parse_code_block(parser: var Parser): Node = 
    CodeBlock(text: parser.take_until("```"))

proc parse_image(parser: var Parser): Node = 
    parser.expect("[")
    var text = parser.pop().data
    parser.expect("]")
    parser.expect("(")
    var url = parser.pop().data
    parser.expect(")")
    Image(text: text, url: url)

proc parse_paragraph(parser: var Parser): Node = 
    Paragraph(children: parser.parse_formatted_text(@["\n"]))

proc parse_node(parser: var Parser): Option[Node] = 
    if parser.accept("#").isSome:
        some(parser.parse_header())
    elif parser.accept("```").isSome:
        some(parser.parse_code_block())
    elif parser.accept("!").isSome:
        some(parser.parse_image())
    elif parser.accept("\n").isSome:
        none(Node)
    else:
        some(parser.parse_paragraph())

proc parse_document(parser: var Parser): seq[Node] =
    var retval = newSeq[Node](0)
    while parser.index < len(parser.tokens) - 1:
        var node = parser.parse_node()
        if node.isSome:
            retval.add(node.get())
    return retval

if paramCount() != 2:
    quit "usage: ./converter <markdown-filename>"
else:
    # Open contents, parse
    var parser: Parser = Parser(tokens: newSeq[Token](0), index: 0)
    parser.tokenize(readFile(paramStr(2)))
    var document = parser.parse_document()
    # Write output
    var outstring = ""
    for node in document:
        outstring.add(node.get_HTML())
    writeFile("output.html", outstring)