import java.io.PrintWriter

// To run: use intellij
// Pros:
//  - I like the distinction between object and class. More holistic with Java IMO
//  - Inline function syntax
//  - Immutability
//  - Functional programming constructs
//  - Optional semicolons
//  - Last expression evaluated in block is block's value
//  - Warnings about unnecessary parens
//  - Cool string interpolation
//  - Fairly strong let/use type inference
// Cons:
//  - Indexing arrays is done with parens
//  - No non-nullability
//  - Uses : instead of -> for function codomain
//  - Runs on the JVM
//  - object oriented rather than data oriented
//  - garbage collected

object Main {
  def main(args: Array[String]): Unit = {
    if (args.length != 1) {
      println("give me markdown filename as CLI input")
    } else {
      val pw = new PrintWriter("output.html")
      pw.write(
        Parser
          .init(scala.io.Source.fromFile(args(0)).mkString)
          .parseDocument()
          .map(node => node.getHTML())
          .mkString(sep = "")
      )
      pw.close()
    }
  }
}