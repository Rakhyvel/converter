import java.util.ArrayList;

public class Italic implements Node {
    public ArrayList<Node> children;

    public Italic(ArrayList<Node> children) {
        this.children = children;
    }

    @Override
    public String getString() {
        String text = "<em>";
        for (Node child : this.children) {
            text += child.getString();
        }
        return text + "</em>";
    }
}
