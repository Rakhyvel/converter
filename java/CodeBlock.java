public class CodeBlock implements Node {
    public String text;

    public CodeBlock(String text) {
        this.text = text;
    }

    @Override
    public String getString() {
        return "<pre><code>" + this.text + "</code></pre>\n";
    }
}
