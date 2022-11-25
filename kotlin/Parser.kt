import kotlin.system.exitProcess

class Parser {
    class Token constructor(val data:String, val line:Int, val col:Int) // Good record syntax!

    private val tokens:MutableList<Token> = mutableListOf()
    private var index = 0

    constructor(contents:String) {
        var data = "" + contents[0]
        var line = 1
        var col = 1
        var oldCol = 1
        var oldC = contents[0]
        for (c in contents.substring(1)) {
            if (oldC == '\n' || oldC == '\r' || (isSpecialChar(oldC) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r') {
                if (!data.contains("\r")) {
                    this.tokens.add(Token(data, line, oldCol))
                }
                oldCol = col + 1
                if (c == '\n') {
                    line ++
                    col = 0
                }
                data = ""
            }
            if (oldC != '#' || !Character.isWhitespace(c)) {
                data += c
            }
            col++
            oldC = c
        }
        this.tokens.add(Token(data, line, col))
        this.tokens.add(Token("\n", line, col))
    }

    private fun isSpecialChar(c:Char):Boolean {
        return c == '_' ||
                c == '*' ||
                c == '`' ||
                c == '#' ||
                c == '[' ||
                c == ']' ||
                c == '(' ||
                c == ')' ||
                c == '!'
    }

    private fun peek():Token {
        return tokens[index]
    }

    private fun pop():Token {
        index++
        return tokens[index - 1]
    }

    private fun accept(data:String):Token? {
        return if (peek().data == data) {
            pop()
        } else {
            null
        }
    }

    private fun takeUntil(data:String):String {
        var retval = ""
        while (accept(data) == null) {
            retval += pop().data
        }
        return retval
    }

    private fun expect(data:String) {
        if (accept(data) == null) {
            val top = this.peek()
            if (isSpecialChar(top.data[0])) {
                println("error: ${top.line}:${top.col} expected `${data}`, got `${top.data}`\n")
            } else {
                println("error: ${top.line}:${top.col} expected `${data}`, got text\n")
            }
            exitProcess(1)
        }
    }

    fun parseDocument():List<Node> {
        val retval = mutableListOf<Node>()
        while (index < tokens.size - 1) {
            val node = parseNode()
            if (node != null) {
                retval.add(node)
            }
        }
        return retval
    }

    private fun parseNode():Node? {
        return if (accept("#") != null) {
            parseHeader()
        } else if (accept("```") != null) {
            parseCodeBlock()
        } else if (accept("!") != null) {
            parseImage()
        } else if (accept("\n") == null) {
            parseParagraph()
        } else {
            null
        }
    }

    private fun parseHeader():Header {
        var size = 1
        while (accept("#") != null) {
            size++
        }
        return Header(size, parseFormattedText(listOf("\n")))
    }

    private fun parseParagraph():Paragraph {
        return Paragraph(parseFormattedText(listOf("\n")))
    }

    private fun parseCodeBlock():CodeBlock {
        return CodeBlock(takeUntil("```"))
    }

    private fun parseImage():Image {
        expect("[")
        val text = pop().data
        expect("]")
        expect("(")
        val url = pop().data
        expect(")")
        return Image(text, url)
    }

    private fun parseFormattedText(bounds:List<String>):List<Node> {
        val retval = mutableListOf<Node>()
        while (!bounds.contains(peek().data)) {
            if (accept("_") != null || accept("*") != null) {
                retval.add(parseItalic(bounds))
            } else if (accept("__") != null || accept("**") != null) {
                retval.add(parseBold(bounds))
            } else if (accept("`") != null) {
                retval.add(parseCode())
            } else if (accept("[") != null) {
                retval.add(parseLink())
            } else {
                retval.add(Text(pop().data))
            }
        }
        return retval
    }

    private fun parseItalic(bounds:List<String>):Italic {
        val newBounds = bounds.toMutableList()
        newBounds.add("*")
        newBounds.add("_")
        val children = parseFormattedText(newBounds)
        if (accept("_") == null) {
            expect("*")
        }
        return Italic(children)
    }

    private fun parseBold(bounds:List<String>):Bold {
        val newBounds = bounds.toMutableList()
        newBounds.add("**")
        newBounds.add("__")
        val children = parseFormattedText(newBounds)
        if (accept("__") == null) {
            expect("**")
        }
        return Bold(children)
    }

    private fun parseCode():Code {
        return Code(takeUntil("`"))
    }

    private fun parseLink():Link {
        val text = pop().data
        expect("]")
        expect("(")
        val url = pop().data
        expect(")")
        return Link(text, url)
    }
}