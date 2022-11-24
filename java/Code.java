public class Code implements Node {
    public String text;

    public Code(String text) {
        this.text = text;
    }

    @Override
    public String getString() {
        return "<code>" + text + "</code>";
    }
}
