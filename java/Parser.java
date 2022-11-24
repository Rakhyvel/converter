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
            if (oldC == '\n' || oldC == '\r' || (isSpecialChar(oldC) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r' ) {
                if (!data.contains("\r")) {
                    tokens.add(new Token(data, line, oldCol));
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
        tokens.add(new Token(data, line, col));
        tokens.add(new Token("\n", line, col));
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
        index++;
        return tokens.get(index - 1);
    }

    private Token peek() {
        return tokens.get(index);
    }

    private Optional<Token> accept(String data) {
        if (peek().data.equals(data)) {
            return Optional.of(pop());
        } else {
            return Optional.empty();
        }
    }

    private void expect(String data) {
        if (!accept(data).isPresent()) {
            Token top = peek();
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
        while (index < tokens.size() - 1) {
            Optional<Node> node = parseNode();
            if (node.isPresent()) {
                retval.add(node.get());
            }
        }
        return retval;
    }

    private Optional<Node> parseNode() {
        if (accept("#").isPresent()) {
            return Optional.of(parseHeader());
        } else if (accept("```").isPresent()) {
            return Optional.of(parseCodeBlock());
        } else if (accept("!").isPresent()) {
            return Optional.of(parseImage());
        } else if (accept("\n").isPresent()) {
            return Optional.empty();
        } else {
            return Optional.of(parseParagraph());
        }
    }

    private Header parseHeader() {
        int size = 1;
        while (accept("#").isPresent()) {
            size++;
        }
        HashSet<String> bounds = new HashSet<String>();
        bounds.add("\n");
        return new Header(size, parseFormattedText(bounds));
    }

    private Paragraph parseParagraph() {
        HashSet<String> bounds = new HashSet<String>();
        bounds.add("\n");
        return new Paragraph(parseFormattedText(bounds));
    }

    private CodeBlock parseCodeBlock() {
        String text = "";
        while (accept("```").isEmpty()) {
            text += pop().data;
        }
        return new CodeBlock(text);
    }

    private Image parseImage() {
        expect("[");
        String text = pop().data;
        expect("]");
        expect("(");
        String url = pop().data;
        expect(")");
        return new Image(text, url);
    }

    private ArrayList<Node> parseFormattedText(HashSet<String> bounds) {
        ArrayList<Node> retval = new ArrayList<>();
        while (!bounds.contains(peek().data)) {
            if (accept("_").isPresent() || accept("*").isPresent()) {
                retval.add(parseItalic(bounds));
            } else if (accept("__").isPresent() || accept("**").isPresent()) {
                retval.add(parseBold(bounds));
            } else if (accept("`").isPresent()) {
                retval.add(parseCode());
            } else if (accept("[").isPresent()) {
                retval.add(parseLink());
            } else {
                retval.add(new Text(pop().data));
            }
        }
        return retval;
    }

    private Italic parseItalic(HashSet<String> bounds) {
        HashSet<String> newBounds = (HashSet<String>)bounds.clone();
        newBounds.add("*");
        newBounds.add("_");
        ArrayList<Node> children = parseFormattedText(newBounds);
        if (accept("*").isEmpty()) {
            expect("_");
        }
        return new Italic(children);
    }

    private Bold parseBold(HashSet<String> bounds) {
        HashSet<String> newBounds = (HashSet<String>)bounds.clone();
        newBounds.add("**");
        newBounds.add("__");
        ArrayList<Node> children = parseFormattedText(newBounds);
        if (accept("**").isEmpty()) {
            expect("__");
        }
        return new Bold(children);
    }

    private Code parseCode() {
        String text = "";
        while (accept("`").isEmpty()) {
            text += pop().data;
        }
        return new Code(text);
    }

    private Link parseLink() {
        String text = pop().data;
        expect("]");
        expect("(");
        String url = pop().data;
        expect(")");
        return new Link(text, url);
    }
}