public interface INode {
    public string GetString();
}

public class Header : INode {
    private int _size;
    private List<INode> _children;

    public Header(int size, List<INode> children) {
        _size = size;
        _children = children;
    }

    public string GetString() {
        string text = "<h" + _size + ">";
        int i = 0;
        foreach (INode child in _children) {
            if (i == 0) {
                text += child.GetString().TrimStart();
            } else {
                text += child.GetString();
            }
            i++;
        }
        return text + "</h" + _size + ">";
    }
}

public class Paragraph : INode {
    private List<INode> _children;

    public Paragraph(List<INode> children) {
        _children = children;
    }

    public string GetString() {
        string text = "<p>";
        foreach (INode child in _children) {
            text += child.GetString();
        }
        return text + "</p>\n";
    }
}

public class CodeBlock : INode {
    private string _text;

    public CodeBlock(string text) {
        _text = text;
    }

    public string GetString() {
        return "<pre><code>" + _text + "</code></pre>\n";
    }
}

public class Image : INode {
    private string _text;
    private string _url;

    public Image(string text, string url) {
        _text = text;
        _url = url;
    }

    public string GetString() {
        return "<img src=\"" + _url + "\" alt=\"" + _text + "\" />\n";
    }
}

public class Text : INode {
    private string _text;

    public Text(string text) {
        _text = text;
    }

    public string GetString() {
        return _text;
    }
}

public class Italic : INode {
    private List<INode> _children;

    public Italic(List<INode> children) {
        _children = children;
    }

    public string GetString() {
        string text = "<em>";
        foreach (INode child in _children) {
            text += child.GetString();
        }
        return text + "</em>";
    }
}

public class Bold : INode {
    private List<INode> _children;

    public Bold(List<INode> children) {
        _children = children;
    }

    public string GetString() {
        string text = "<strong>";
        foreach (INode child in _children) {
            text += child.GetString();
        }
        return text + "</strong>";
    }
}

public class Code : INode {
    private string _text;

    public Code(string text) {
        _text = text;
    }

    public string GetString() {
        return "<code>" + _text + "</code>";
    }
}

public class Link : INode {
    private string _text;
    private string _url;

    public Link(string text, string url) {
        _text = text;
        _url = url;
    }

    public string GetString() {
        return "<a href=\"" + _url + "\">" + _text + "</a>";
    }
}