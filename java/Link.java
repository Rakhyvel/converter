public class Link implements Node {
    public String text;
    public String url;

    public Link(String text, String url) {
        this.text = text;
        this.url = url;
    }

    @Override
    public String getString() {
        return "<a href=\"" + this.url + "\">" + this.text + "</a>";
    }
}
