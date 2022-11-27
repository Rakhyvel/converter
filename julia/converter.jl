# To run: julia converter.jl ../input.md
# Pros:
#   - Multi-methods are neat!
#   - File IO is super easy
#   - Really clean syntax
#   - String interpolation
#   - Expression function syntax
# Cons:
#   - Arrays are 1-indexed

abstract type Node end

struct Header <: Node
    size::Int
    children::Vector{Node}
end

getHTML(header::Header) = "<h$(header.size)>$(join(map(child->getHTML(child), header.children), ""))</h$(header.size)>\n"

struct Paragraph <: Node
    children::Vector{Node}
end

getHTML(paragraph::Paragraph) = "<p>$(join(map(child->getHTML(child), paragraph.children), ""))</p>\n\n"

struct CodeBlock <: Node
    text::String
end

getHTML(codeblock::CodeBlock) = "<pre><code>$(codeblock.text)</code></pre>\n\n"

struct Image <: Node
    text::String
    url::String
end

getHTML(image::Image) = "<img src=\"$(image.url)\" alt=\"$(image.text)\" />"

struct Text <: Node
    text::String
end

getHTML(text::Text) = "$(text.text)"

struct Italic <: Node
    children::Vector{Node}
end

getHTML(italic::Italic) = "<em>$(join(map(child->getHTML(child), italic.children), ""))</em>"

struct Bold <: Node
    children::Vector{Node}
end

getHTML(bold::Bold) = "<strong>$(join(map(child->getHTML(child), bold.children), ""))</strong>"

struct Code <: Node
    text::String
end

getHTML(code::Code) = "<code>$(code.text)</code>"

struct Link <: Node
    text::String
    url::String
end

getHTML(link::Link) = "<a href=\"$(link.url)\">$(link.text)</a>"

struct Token
    data::String
    line::Int
    col::Int
end

mutable struct Parser
    index::Int
    tokens::Vector{Token}
end

function createParser(contents::String)
    parser::Parser = Parser(1, [])

    data::String = SubString(contents, 1, 1)
    line::Int = 1
    col::Int = 1
    oldCol::Int = 1
    oldC::Char = data[1]
    for c::Char in SubString(contents, 2)
        if oldC == '\n' || oldC == '\r' || (isSpecialChar(oldC) != isSpecialChar(c)) || contains("#[(!\n\r", string(c))
            if !contains(data, "\r")
                push!(parser.tokens, Token(data, line, oldCol))
            end
            oldCol = col + 1
            if c == '\n'
                line += 1
                col = 0
            end
            data = ""
        end
        if oldC != '#' || !isspace(c)
            data = string(data, c)
        end
        col += 1
        oldC = c
    end
    push!(parser.tokens, Token(data, line, col))
    push!(parser.tokens, Token("\n", line, col))

    parser
end

isSpecialChar(c::Char) = contains("_*`#[]()!", string(c))

function pop(parser::Parser)
    parser.index += 1
    parser.tokens[parser.index - 1]
end

peek(parser::Parser) = parser.tokens[parser.index]

accept(parser::Parser, data::String) =
    if peek(parser).data == data
        pop(parser)
    else
        nothing
    end

expect(parser::Parser, data::String) =
    if accept(parser, data) === nothing
        top = peek(parser)
        if isSpecialChar(top.data[1])
            println("error: $(top.line):$(top.col) expected `$(data)` got `$(top.data)`")
        else
            println("error: $(top.line):$(top.col) expected `$(data)` got text")
        end
        exit(1)
    end


takeUntil(parser::Parser, sentinel::String) = 
    if accept(parser, sentinel) === nothing
        pop(parser).data * takeUntil(parser, sentinel)
    else
        ""
    end

parseDocument(parser::Parser) =
    if parser.index < length(parser.tokens) - 1
        node = parseNode(parser)
        rest = parseDocument(parser)
        if node !== nothing 
            push!(rest, node)
        end
        rest
    else
        []
    end

parseNode(parser::Parser) =
    if accept(parser, "#") !== nothing
        parseHeader(parser)
    elseif accept(parser, "```") !== nothing
        parseCodeBlock(parser)
    elseif accept(parser, "!") !== nothing
        parseImage(parser)
    elseif accept(parser, "\n") === nothing
        parseParagraph(parser)
    else
        nothing
    end

function parseHeader(parser::Parser)
    size = 1
    while accept(parser, "#") !== nothing
        size += 1
    end
    Header(size, parseFormattedText(parser, ["\n"]))
end

parseParagraph(parser::Parser) = Paragraph(parseFormattedText(parser, ["\n"]))

parseCodeBlock(parser::Parser) = CodeBlock(takeUntil(parser, "```"))

function parseImage(parser::Parser)
    expect(parser, "[")
    text = pop(parser).data
    expect(parser, "]")
    expect(parser, "(")
    url = pop(parser).data
    expect(parser, ")")
    Image(text, url)
end

function parseFormattedText(parser::Parser, bounds::Vector{String})
    retval = []
    while !issubset([peek(parser).data], bounds)
        if accept(parser, "_") !== nothing || accept(parser, "*") !== nothing
            push!(retval, parseItalic(parser, copy(bounds)))
        elseif accept(parser, "__") !== nothing || accept(parser, "**") !== nothing
            push!(retval, parseBold(parser, copy(bounds)))
        elseif accept(parser, "`") !== nothing
            push!(retval, parseCode(parser))
        elseif accept(parser, "[") !== nothing
            push!(retval, parseLink(parser))
        else
            push!(retval, Text(pop(parser).data))
        end 
    end
    retval
end

function parseItalic(parser::Parser, bounds::Vector{String})
    push!(bounds, "*")
    push!(bounds, "_")
    children = parseFormattedText(parser, bounds)
    if accept(parser, "*") === nothing
        expect(parser, "_")
    end
    Italic(children)
end

function parseBold(parser::Parser, bounds::Vector{String})
    push!(bounds, "**")
    push!(bounds, "__")
    children = parseFormattedText(parser, bounds)
    if accept(parser, "**") === nothing
        expect(parser, "__")
    end
    Bold(children)
end

parseCode(parser::Parser) = Code(takeUntil(parser, "`"))

function parseLink(parser::Parser)
    text = pop(parser).data
    expect(parser, "]")
    expect(parser, "(")
    url = pop(parser).data
    expect(parser, ")")
    Link(text, url)
end

if length(ARGS) != 1
    println("usage: julia converter.jl <markdown-filename>")
else
    # Open input file, read contents
    f = open(ARGS[1])
    output = open("output.html", "w")
    write(output, "$(join(map(node->getHTML(node), reverse(parseDocument(createParser(read(f, String))))), ""))")
    close(output)
    close(f)
end