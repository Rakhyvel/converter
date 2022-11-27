# To run: ruby converter.rb ../input.md
# Pros:
#   - Last thing in a block is eval"d
# Cons:
#   - Instance variables are private
#   - `elsif`

class Node
    def get_HTML
        raise "shouldnt be called"
    end
end

class Header < Node
    def initialize(size, children)
        @size = size
        @children = children
    end

    def get_HTML
        "<h#{@size}>#{@children.map{|child| child.get_HTML}.join("")}</h#{@size}>\n"
    end
end

class Paragraph < Node
    def initialize(children)
        @children = children
    end

    def get_HTML
        "<p>#{@children.map{|child| child.get_HTML}.join("")}</p>\n\n"
    end
end

class CodeBlock < Node
    def initialize(text)
        @text = text
    end

    def get_HTML
        "<pre><code>#{@text}</code></pre>\n\n"
    end
end

class Image < Node
    def initialize(text, url)
        @text = text
        @url = url
    end

    def get_HTML
        "<img src=\"#{@url}\" alt=\"#{@text}\" />"
    end
end

class Text < Node
    def initialize(text)
        @text = text
    end

    def get_HTML
        @text
    end
end

class Italic < Node
    def initialize(children)
        @children = children
    end

    def get_HTML
        "<em>#{@children.map{|child| child.get_HTML}.join("")}</em>"
    end
end

class Bold < Node
    def initialize(children)
        @children = children
    end

    def get_HTML
        "<strong>#{@children.map{|child| child.get_HTML}.join("")}</strong>"
    end
end

class Code < Node
    def initialize(text)
        @text = text
    end

    def get_HTML
        "<code>#{@text}</code>"
    end
end

class Link < Node
    def initialize(text, url)
        @text = text
        url = url
    end

    def get_HTML
        "<a href=\"#{@url}\">#{@text}</a>"
    end
end

class Token
    def initialize(data, line, col)
        @data = data
        @line = line
        @col = col
    end

    def data
        @data
    end

    def line
        @line
    end

    def col
        @col
    end
end

class Parser
    def initialize(contents)
        @tokens = []
        @index = 0

        data = contents[0]
        line = 1
        col = 1
        old_col = 1
        old_c = data
        contents[1..].chars().each() do |c|
            if old_c == "\n" or old_c == "\r" or ((is_special_char(old_c)) != (is_special_char(c))) or c == "#" or c == "[" or c == "(" or c == "!" or c == "\r" or c == "\n"
                @tokens.append(Token.new(data.gsub("\r", ""), line, old_col))
                old_col = col + 1
                if c == "\n"
                    line += 1
                    col = 0
                end
                data = ""
            end
            if old_c != "#" or not c =~ /\s/
                data += c
            end
            col += 1
            old_c = c
        end
        @tokens.append(Token.new(data, line, col))
        @tokens.append(Token.new("\n", line, col))
    end

    def is_special_char(c) 
        c == "_" or
        c == "*" or
        c == "`" or
        c == "#" or
        c == "[" or
        c == "]" or
        c == "(" or
        c == ")" or
        c == "!"
    end

    def pop
        @index += 1
        @tokens[@index - 1]
    end

    def peek
        @tokens[@index]
    end

    def accept(data)
        if peek().data == data
            pop().data
        else
            nil
        end
    end

    def expect(data)
        if accept(data) == nil
            top = peek()
            if is_special_char(top.data[0])
                puts "error: #{top.line}:#{top.col} expected `#{data}` got `#{top.data}`"
            else
                puts "error: #{top.line}:#{top.col} expected `#{data}` got text"
            end
            fail
        end
    end

    def take_until(sentinel)
        text = ""
        while accept(sentinel) == nil
            text += pop().data
        end
        text
    end

    def parse_document
        retval = []
        while @index < @tokens.length - 1
            node = parse_node()
            if node != nil
                retval.append node
            end
        end
        retval
    end

    def parse_node
        if accept("#")
            parse_header()
        elsif accept("```")
            parse_code_block()
        elsif accept("!")
            parse_image()
        elsif accept("\n")
            nil
        else
            parse_paragraph()
        end
    end

    def parse_header
        size = 1
        while accept("#")
            size += 1
        end
        Header.new(size, parse_formatted_text(["\n"]))
    end

    def parse_paragraph
        Paragraph.new(parse_formatted_text(["\n"]))
    end

    def parse_code_block
        CodeBlock.new(take_until("```"))
    end

    def parse_image
        expect("[")
        text = pop().data
        expect("]")
        expect("(")
        url = pop().data
        expect(")")
        Image.new(text, url)
    end

    def parse_formatted_text(bounds)
        retval = []
        while not bounds.include?(peek().data)
            if accept("_") or accept("*")
                retval.append(parse_italic(bounds))
            elsif accept("__") or accept("**")
                retval.append(parse_bold(bounds))
            elsif accept("`")
                retval.append(parse_code())
            elsif accept("[")
                retval.append(parse_link())
            else
                retval.append(Text.new(pop().data))
            end
        end
        retval
    end

    def parse_italic(bounds)
        newBounds = []
        bounds.each do |b|
            newBounds.append  b
        end
        newBounds.append "*"
        newBounds.append "_"
        children = parse_formatted_text(newBounds)
        if not accept("*")
            expect("_")
        end
        Italic.new(children)
    end

    def parse_bold(bounds)
        newBounds = []
        bounds.each do |b|
            newBounds.append  b
        end
        newBounds.append "**"
        newBounds.append "__"
        children = parse_formatted_text(newBounds)
        if not accept("**")
            expect("__")
        end
        Bold.new(children)
    end

    def parse_code
        Code.new(take_until("`"))
    end

    def parse_link
        text = pop().data
        expect("]")
        expect("(")
        url = pop().data
        expect(")")
        Link.new(text, url)
    end
end

# Open input file, read contents
if ARGV.length != 1 
    puts "usage: ruby converter.rb <markdown-filename>"
else
    File.open("output.html", 'w') do |file| 
        Parser.new(File.read(ARGV[0])).parse_document.each do |node|
            file.write node.get_HTML
        end
    end
end

# Create parser, parse document

# Open output file, write ouput