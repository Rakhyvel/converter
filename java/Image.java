public class Image implements Node {
    public String text;
    public String url;

    public Image(String text, String url) {
        this.text = text;
        this.url = url;
    }

    @Override
    public String getString() {
        return "<img src=\"" + this.url + "\" alt=\"" + this.text + "\" />\n";
    }
}
