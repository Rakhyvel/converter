import java.util.ArrayList;

public class Bold implements Node {
    public ArrayList<Node> children;

    public Bold(ArrayList<Node> children) {
        this.children = children;
    }

    @Override
    public String getString() {
        String text = "<strong>";
        for (Node child : children) {
            text += child.getString();
        }
        return text + "</strong>";
    }
}
