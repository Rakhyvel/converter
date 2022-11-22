import java.util.ArrayList;
import java.util.HashSet;
import java.util.Optional;

public class Parser {
    private class Token {
        public String data;
        public int line;
        public int col;

        public Token(String data, int line, int col) {
            this.data = data;
            this.line = line;
            this.col = col;
        }
    }

    private ArrayList<Token> tokens = new ArrayList<>();
    private int index;


    public Parser(String contents) {
        String data = "" + contents.charAt(0);
        int line = 1;
        int col = 1;
        int oldCol = 1;
        char oldC = contents.charAt(0);
        for (char c : contents.substring(1).toCharArray()) {
            if (oldC == '\n' || oldC == '\r' || (this.isSpecialChar(oldC) != this.isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r' ) {
                if (!data.contains("\r")) {
                    this.tokens.add(new Token(data, line, col));
                }
                oldCol = col + 1;
                if (c == '\n') {
                    line++;
                    col = 0;
                }
                data = "";
            }
            if (oldC != '#' || !Character.isWhitespace(c)) {
                data += c;
            }
            col++;
            oldC = c;
        }
        this.tokens.add(new Token(data, line, col));
        this.tokens.add(new Token("\n", line, col));
    }

    private boolean isSpecialChar(char c) {
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

    private Token pop() {
        this.index++;
        return this.tokens.get(this.index - 1);
    }

    private Token peek() {
        return this.tokens.get(this.index);
    }

    private Optional<Token> accept(String data) {
        if (this.tokens.get(this.index).data.equals(data)) {
            return Optional.of(this.pop());
        } else {
            return Optional.empty();
        }
    }

    private void expect(String data) {
        Optional<Token> res = this.accept(data);
        if (!res.isPresent()) {
            Token top = this.peek();
            if (isSpecialChar(top.data.charAt(0))) {
                System.err.printf("error: %d:%d expected `%s` got `%s`\n", top.line, top.col, data, top.data);
            } else {
                System.err.printf("error: %d:%d expected `%s` got text\n", top.line, top.col, data);
            }
            System.exit(1);
        }
    }

    public ArrayList<Node> parseDocument() {
        ArrayList<Node> retval = new ArrayList<>();
        while (this.index < this.tokens.size() - 1) {
            Optional<Node> node = this.parseNode();
            if (node.isPresent()) {
                retval.add(node.get());
            }
        }
        return retval;
    }

    private Optional<Node> parseNode() {
        if (this.accept("#").isPresent()) {
            return Optional.of(this.parseHeader());
        } else if (this.accept("```").isPresent()) {
            return Optional.of(this.parseCodeBlock());
        } else if (this.accept("!").isPresent()) {
            return Optional.of(this.parseImage());
        } else if (this.accept("\n").isPresent()) {
            return Optional.empty();
        } else {
            return Optional.of(this.parseParagraph());
        }
    }

    private Header parseHeader() {
        int size = 1;
        while (this.accept("#").isPresent()) {
            size++;
        }
        HashSet<String> bounds = new HashSet<String>();
        bounds.add("\n");
        return new Header(size, this.parseFormattedText(bounds));
    }

    private Paragraph parseParagraph() {
        HashSet<String> bounds = new HashSet<String>();
        bounds.add("\n");
        return new Paragraph(this.parseFormattedText(bounds));
    }

    private CodeBlock parseCodeBlock() {
        String text = "";
        while (this.accept("```").isEmpty()) {
            text += this.pop().data;
        }
        return new CodeBlock(text);
    }

    private Image parseImage() {
        this.expect("[");
        String text = this.pop().data;
        this.expect("]");
        this.expect("(");
        String url = this.pop().data;
        this.expect(")");
        return new Image(text, url);
    }

    private ArrayList<Node> parseFormattedText(HashSet<String> bounds) {
        ArrayList<Node> retval = new ArrayList<>();
        while (!bounds.contains(this.peek().data)) {
            if (this.accept("_").isPresent() || this.accept("*").isPresent()) {
                retval.add(this.parseItalic(bounds));
            } else if (this.accept("__").isPresent() || this.accept("**").isPresent()) {
                retval.add(this.parseBold(bounds));
            } else if (this.accept("`").isPresent()) {
                retval.add(this.parseCode());
            } else if (this.accept("[").isPresent()) {
                retval.add(this.parseLink());
            } else {
                retval.add(new Text(this.pop().data));
            }
        }
        return retval;
    }

    private Italic parseItalic(HashSet<String> bounds) {
        HashSet<String> newBounds = (HashSet<String>)bounds.clone();
        newBounds.add("*");
        newBounds.add("_");
        ArrayList<Node> children = this.parseFormattedText(newBounds);
        if (this.accept("*").isEmpty()) {
            this.expect("_");
        }
        return new Italic(children);
    }

    private Bold parseBold(HashSet<String> bounds) {
        HashSet<String> newBounds = (HashSet<String>)bounds.clone();
        newBounds.add("**");
        newBounds.add("__");
        ArrayList<Node> children = this.parseFormattedText(newBounds);
        if (this.accept("**").isEmpty()) {
            this.expect("__");
        }
        return new Bold(children);
    }

    private Code parseCode() {
        String text = "";
        while (this.accept("`").isEmpty()) {
            text += this.pop().data;
        }
        return new Code(text);
    }

    private Link parseLink() {
        String text = this.pop().data;
        this.expect("]");
        this.expect("(");
        String url = this.pop().data;
        this.expect(")");
        return new Link(text, url);
    }
}