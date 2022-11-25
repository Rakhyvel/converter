interface Node {
    fun getHTML():String
}

class Header constructor(private val size:Int, private val children:List<Node>) : Node  {
    override fun getHTML(): String {
        var text = "<h$size>"
        for (child in children) {
            text += child.getHTML()
        }
        return "$text</h$size>\n"
    }
}

class Paragraph constructor(private val children:List<Node>) : Node  {
    override fun getHTML(): String {
        var text = "<p>"
        for (child in children) {
            text += child.getHTML()
        }
        return "$text</p>\n\n"
    }
}

class CodeBlock constructor(private val text:String) : Node  {
    override fun getHTML(): String {
        return "<pre><code>$text</code></pre>\n\n"
    }
}

class Image constructor(private val text:String, private val url:String) : Node  {
    override fun getHTML(): String {
        return "<img src=\"$url\" alt=\"$text\" />\n\n"
    }
}

class Text constructor(private val text:String) : Node  {
    override fun getHTML(): String {
        return text
    }
}

class Italic constructor(private val children:List<Node>) : Node  {
    override fun getHTML(): String {
        var text = "<em>"
        for (child in children) {
            text += child.getHTML()
        }
        return "$text</em>"
    }
}

class Bold constructor(private val children:List<Node>) : Node  {
    override fun getHTML(): String {
        var text = "<strong>"
        for (child in children) {
            text += child.getHTML()
        }
        return "$text</strong>"
    }
}

class Code constructor(private val text:String) : Node  {
    override fun getHTML(): String {
        return "<code>$text</code>"
    }
}

class Link constructor(private val text:String, private val url:String) : Node  {
    override fun getHTML(): String {
        return "<a href=\"$url\">$text</a>"
    }
}