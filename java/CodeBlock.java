public class CodeBlock implements Node {
    public String text;

    public CodeBlock(String text) {
        this.text = text;
    }

    @Override
    public String getString() {
        return "<pre><code>" + text + "</code></pre>\n\n";
    }
}
