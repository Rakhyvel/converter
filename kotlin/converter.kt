import java.io.File

// Pros:
//  - Not everything is in a class
//  - Immutability
//  - Concise record-like class syntax
//  - Nullables
//  - if-else as ternary operator, hints if a `return` can be lifted out of `if-else`
//  - AMAZING string formatting
//  - Great file IO
// Cons:
//  - HAVE TO HAVE INTELLIJ, WTF! LAME!
//  - Parens around if and while and for loop headers
//  - : function type declaration
//  - 'boolean' type name rather than `bool`
//  - Slow as hell to compile and run

fun main(args: Array<String>) {
    if (args.size != 1) {
        println("please provide input markdown file")
    } else {
        // Open input file, read in contents
        val contents = File(args[0]).readText()

        // Create parser, parse document
        val parser = Parser(contents)
        val document = parser.parseDocument()

        // Write out document
        var output = ""
        for (node in document) {
            output += node.getHTML()
        }
        File("output.html").writeText(output)
    }
}