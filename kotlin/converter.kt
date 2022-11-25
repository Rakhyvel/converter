import java.io.File

// Pros:
//  - Not everything is in a class
//  - Immutability
//  - Concise record-like class syntax
//  - Nullables
//  - if-else as ternary operator, hints if a `return` can be lifted out of `if-else`
//  - AMAZING string formatting
//  - Great file IO
//  - `when` statement matches on type
//  - Good functional programming methods
//  - Can use `=` for functions that are just one expression
// Cons:
//  - HAVE TO HAVE INTELLIJ, WTF! LAME!
//  - Parens around if and while and for loop headers
//  - : function type declaration
//  - 'boolean' type name rather than `bool`
//  - Slow as hell to compile and run

fun main(args: Array<String>) = if (args.size != 1) {
        println("please provide input markdown file")
    } else {
        File("output.html").writeText(
                Parser(File(args[0]).readText())
                        .parseDocument()
                        .joinToString(separator="") { getHTML(it) }
        )
    }

abstract class Node
class Header constructor(val size:Int, val children:List<Node>) : Node()
class Paragraph constructor(val children:List<Node>) : Node()
class CodeBlock constructor(val text:String) : Node()
class Image constructor(val text:String, val url:String) : Node()
class Text constructor(val text:String) : Node()
class Italic constructor(val children:List<Node>) : Node()
class Bold constructor(val children:List<Node>) : Node()
class Code constructor(val text:String) : Node()
class Link constructor(val text:String, val url:String) : Node()

fun getHTML(node:Node):String = when(node) {
    is Header -> "<h${node.size}>${node.children.joinToString(separator="") { getHTML(it) }}</h${node.size}>\n"
    is Paragraph -> "<p>${node.children.joinToString(separator="") { getHTML(it) }}</p>\n\n"
    is CodeBlock -> "<pre><code>${node.text}</code></pre>\n\n"
    is Image -> "<img src=\"${node.url}\" alt=\"${node.text}\" />\n\n"
    is Text -> node.text
    is Italic -> "<em>${node.children.joinToString(separator="") { getHTML(it) }}</em>"
    is Bold -> "<strong>${node.children.joinToString(separator="") { getHTML(it) }}</strong>"
    is Code -> "<code>${node.text}</code>"
    is Link -> "<a href=\"${node.url}\">${node.text}</a>"
    else -> ""
}