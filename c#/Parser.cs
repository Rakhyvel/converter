class Parser {
    private class Token {
        public string Data;
        public int Line;
        public int Col;

        public Token(string data, int line, int col) {
            Data = data;
            Line = line;
            Col = col;
        }
    }

    private List<Token> _tokens = new List<Token>();
    private int _index;

    public Parser(string contents) {
        string data = "" + contents[0];
        int line = 1;
        int col = 1;
        int oldCol = 1;
        char oldC = contents[0];
        foreach (char c in contents.Substring(1)) {
            if (oldC == '\n' || oldC == '\r' || (IsSpecialChar(oldC) != IsSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r') {
                if (!data.Contains("\r")) {
                    _tokens.Add(new Token(data, line, oldCol));
                }
                oldCol = col + 1;
                if (c == '\n') {
                    line ++;
                    col = 0;
                }
                data = "";
            }
            if (oldC != '#' || !Char.IsWhiteSpace(c)) {
                data += c;
            }
            col++;
            oldC = c;
        }
        _tokens.Add(new Token(data, line, col));
        _tokens.Add(new Token("\n", line, col));
    }

    private bool IsSpecialChar(char c) {
        return c == '_' ||
            c == '*' ||
            c == '`' ||
            c == '#' ||
            c == '[' ||
            c == ']' ||
            c == '(' ||
            c == ')' ||
            c == '!';
    }

    private Token Pop() {
        _index++;
        return _tokens[_index - 1];
    }

    private Token Peek() {
        return _tokens[_index];
    }

    private Token? Accept(string data) {
        if (Peek().Data.Equals(data)) {
            return Pop();
        } else {
            return null;
        }
    }

    private void Expect(string data) {
        if (Accept(data) == null) {
            Token top = Peek();
            if (IsSpecialChar(top.Data[0])) {
                Console.WriteLine("error: {0}:{1} expected `{2}` got `{3}`\n", top.Line, top.Col, data, top.Data);
            } else {
                Console.WriteLine("error: {0}:{1} expected `{2}` got text\n", top.Line, top.Col, data);
            }
            System.Environment.Exit(1);
        }
    }

    public List<INode> ParseDocument() {
        List<INode> retval = new List<INode>();
        while (_index < _tokens.Count - 1) {
            INode? node = ParseNode();
            if (node != null) {
                retval.Add(node);
            }
        }
        return retval;
    }

    private INode? ParseNode() {
        if (Accept("#") != null) {
            return ParseHeader();
        } else if (Accept("```") != null) {
            return ParseCodeBlock();
        } else if (Accept("!") != null) {
            return ParseImage();
        } else if (Accept("\n") != null) {
            return null;
        } else {
            return ParseParagraph();
        }
    }

    private Header ParseHeader() {
        int size = 1;
        while (Accept("#") != null) {
            size++;
        }
        HashSet<string> bounds = new HashSet<string>();
        bounds.Add("\n");
        return new Header(size, ParseFormattedText(bounds));
    }

    private Paragraph ParseParagraph() {
        HashSet<string> bounds = new HashSet<string>();
        bounds.Add("\n");
        return new Paragraph(ParseFormattedText(bounds));
    }

    private CodeBlock ParseCodeBlock() {
        string text = "";
        while(Accept("```") == null) {
            text += Pop().Data;
        }
        return new CodeBlock(text);
    }

    private Image ParseImage() {
        Expect("[");
        string text = Pop().Data;
        Expect("]");
        Expect("(");
        string url = Pop().Data;
        Expect(")");
        return new Image(text, url);
    }

    private List<INode> ParseFormattedText(HashSet<string> bounds) {
        List<INode> retval = new List<INode>();
        while (!bounds.Contains(Peek().Data)) {
            if (Accept("_") != null || Accept("*") != null) {
                retval.Add(ParseItalic(bounds));
            } else if (Accept("__") != null || Accept("**") != null) {
                retval.Add(ParseBold(bounds));
            } else if (Accept("`") != null) {
                retval.Add(ParseCode());
            } else if (Accept("[") != null) {
                retval.Add(ParseLink());
            } else {
                retval.Add(new Text(Pop().Data));
            }
        }
        return retval;
    }

    private Italic ParseItalic(HashSet<string> bounds) {
        HashSet<string> newBounds = new HashSet<string>(bounds);
        newBounds.Add("*");
        newBounds.Add("_");
        List<INode> children = ParseFormattedText(newBounds);
        if (Accept("*") == null) {
            Expect("_");
        }
        return new Italic(children);
    }

    private Bold ParseBold(HashSet<string> bounds) {
        HashSet<string> newBounds = new HashSet<string>(bounds);
        newBounds.Add("**");
        newBounds.Add("__");
        List<INode> children = ParseFormattedText(newBounds);
        if (Accept("**") == null) {
            Expect("__");
        }
        return new Bold(children);
    }

    private Code ParseCode() {
        string text = "";
        while(Accept("`") == null) {
            text += Pop().Data;
        }
        return new Code(text);
    }

    private Link ParseLink() {
        string text = Pop().Data;
        Expect("]");
        Expect("(");
        string url = Pop().Data;
        Expect(")");
        return new Link(text, url);
    }
}