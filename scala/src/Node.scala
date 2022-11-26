trait Node {
  def getHTML():String
}

class Header (val size:Int, val children:List[Node]) extends Node {
  def getHTML() = s"<h$size>${children.map(child => child.getHTML()).mkString(sep="")}</h$size>\n"
}

class Paragraph (val children:List[Node])extends Node {
  def getHTML() = s"<p>${children.map(child => child.getHTML()).mkString(sep = "")}</p>\n\n"
}

class CodeBlock (val text:String)extends Node {
  def getHTML() = s"<pre><code>$text</code></pre>\n\n"
}

class Image (val text:String, val url:String)extends Node {
  def getHTML() = s"<img src=\"$url\" alt=\"$text\" />\n\n"
}

class Text (val text:String)extends Node {
  def getHTML() = text
}

class Italic (val children:List[Node])extends Node {
  def getHTML() = s"<em>${children.map(child => child.getHTML()).mkString(sep = "")}</em>"
}

class Bold (val children:List[Node])extends Node {
  def getHTML() = s"<strong>${children.map(child => child.getHTML()).mkString(sep = "")}</strong>"
}

class Code (val text:String)extends Node {
  def getHTML() = s"<code>$text</code>"
}

class Link (val text:String, val url:String)extends Node {
  def getHTML() = s"<a href=\"$url\">$text</a>"
}