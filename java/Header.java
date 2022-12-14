import java.util.ArrayList;

public class Header implements Node {
    public int size;
    public ArrayList<Node> children;

    public Header(int size, ArrayList<Node> children) {
        this.size = size;
        this.children = children;
    }

    @Override
    public String getString() {
        String text = "<h" + size + ">";
        int i = 0;
        for (Node child : children) {
            if (i == 0) {
                text += child.getString().strip();
            } else {
                text += child.getString();
            }
            i++;
        }
        return text + "</h" + size + ">\n";
    }
}
