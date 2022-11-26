object Parser {
  class Token (val data:String, val line:Int, val col:Int)

  private var index:Int = 0
  private var tokens:List[Token] = Nil

  def init(contents:String):Parser.type = {
    var data = "" + contents(0)
    var line = 1
    var col = 1
    var oldCol = 1
    var oldC = contents(0)
    var tokens:List[Token] = Nil
    for (c <- contents.substring(1)) {
      if (oldC == '\n' || oldC == '\r' || (isSpecialChar(oldC) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r') {
        if (!data.contains("\r")) {
          tokens = new Token(data, line, oldCol) :: tokens
        }
        oldCol = col + 1
        if (c == '\n') {
          line += 1
          col = 0
        }
        data = ""
      }
      if (oldC != '#' || !Character.isWhitespace(c)) {
        data += c
      }
      col += 1
      oldC = c
    }
    tokens = new Token(data, line, col) :: tokens
    tokens = new Token("\n", line, col) :: tokens
    this.tokens = tokens.reverse
    this
  }

  private def isSpecialChar (c: Char) =
    c == '_' ||
    c == '*' ||
    c == '`' ||
    c == '#' ||
    c == '[' ||
    c == ']' ||
    c == '(' ||
    c == ')' ||
    c == '!'

  private def pop() = {
    this.index += 1
    this.tokens(this.index - 1)
  }

  private def peek() = this.tokens(this.index)

  private def accept(data:String) =
    if (peek().data == data) {
      pop()
    } else {
      null
    }

  private def expect(data:String):Unit = if (accept(data) == null) {
    val top = peek()
    if (isSpecialChar(top.data(0))) {
      println(s"error: ${top.line}:${top.col} expected `$data`, got `${top.data}`.\n")
    } else {
      println(s"error: ${top.line}:${top.col} expected `$data`, got text.\n")
    }
    System.exit(1)
  }

  private def takeUntil(sentinel:String):String =
    if (accept(sentinel) == null) {
      pop().data + takeUntil(sentinel)
    } else {
      ""
    }

  def parseDocument():List[Node] =
    if (index < tokens.length - 1) {
      val node = parseNode()
      val rest = parseDocument()
      if (node != null) {
        node :: rest
      } else {
        rest
      }
    } else {
      Nil
    }

  private def parseNode():Node =
    if (accept("#") != null) {
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

  private def count():Int =
    if (accept("#") != null) {
      count() + 1
    } else {
      1
    }

  private def parseHeader() = {
    Header(count(), parseFormattedText(List("\n")))
  }

  private def parseParagraph() = Paragraph(parseFormattedText(List("\n")))

  private def parseCodeBlock() = CodeBlock(takeUntil("```"))

  private def parseImage() = {
    expect("[")
    val text = pop().data
    expect("]")
    expect("(")
    val url = pop().data
    expect(")")
    Image(text, url)
  }

  private def parseFormattedText(bounds:List[String]):List[Node] = {
    var retval:List[Node] = List()
    while (!bounds.contains(peek().data)) {
      if (accept("_") != null || accept("*") != null) {
        retval = parseItalic("_"::"*"::bounds) :: retval
      } else if (accept("__") != null || accept("**") != null) {
        retval = parseBold("__"::"**"::bounds) :: retval
      } else if (accept("`") != null) {
        retval = parseCode() :: retval
      } else if (accept("[") != null) {
        retval = parseLink() :: retval
      } else {
        retval = new Text(pop().data) :: retval
      }
    }
    retval.reverse
  }

  private def parseItalic(bounds:List[String]) = {
    val children = parseFormattedText(bounds)
    if (accept("_") == null) {
      expect("*")
    }
    Italic(children)
  }

  private def parseBold(bounds:List[String]) = {
    val children = parseFormattedText(bounds)
    if (accept("__") == null) {
      expect("**")
    }
    Bold(children)
  }

  private def parseCode() = Code(takeUntil("`"))

  private def parseLink() = {
    val text = pop().data
    expect("]")
    expect("(")
    val url = pop().data
    expect(")")
    Link(text, url)
  }
}