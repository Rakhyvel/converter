import java.util.ArrayList;

public class Paragraph implements Node {
    public ArrayList<Node> children;

    public Paragraph(ArrayList<Node> children) {
        this.children = children;
    }

    @Override
    public String getString() {
        String text = "<p>";
        for (Node child : this.children) {
            text += child.getString();
        }
        return text + "</p>\n";
    }
}
