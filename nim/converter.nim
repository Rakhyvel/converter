# To run: nim compile --run converter.nim -- ../input.md
# Pros:
#   - Pretty terse and simple
#   - Strings are fairly easy
#   - I like the UFCS style of OOP, it's honestly not too bad!
#   - Immutability
#   - Function body is result
#   - Generics work fairly well
#   - Able to chain `type` and probably `let`, `var`, `const`s, pretty neat!
# Cons:
#   - Weird data model, with sequences and stuff, but no access to lower level stuff
#   - Have to define procs in order. Maybe just a lang-server thing?
#   - Identifiers are just undefined if they're not defined. I'd rather have an error, when is that behavior ever desired?
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
        text: string
    Bold = ref object of Node
        text: string
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

proc is_special_char(c: char): bool = c in @['_', '*', '`', '#', '[', ']', '(', ')', '!']

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

# Open contents, parse
var parser: Parser = Parser(tokens: newSeq[Token](0), index: 0)
parser.tokenize(readFile(paramStr(2)))

# Write output