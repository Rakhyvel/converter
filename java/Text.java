public class Text implements Node {
    public String text;

    public Text(String text) {
        this.text = text;
    }

    @Override
    public String getString() {
        return this.text;
    }
}
