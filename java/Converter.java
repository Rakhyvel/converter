// To run: javac *.java && java Converter ../input.md
// Pros:
//  - Concise class method syntax since all methods are inner
//  - Feels natural. Was VERY easy to implement
//  - Foreach
//  - Optionals
//  - Error if method doesn't return value for all control paths
//  - Warnings about unused variables
// Cons:
//  - Everything is in a class
//  - No way to compile and run everything, class files clutter everything. Most IDEs separate .class and .java files, but that's too much work
//  - full 'boolean' type instead of 'bool'
//  - Unnecessary parens around if and while and for
//  - Must define each public class in a separate file
//  - Lots of boilerplate for small classes

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.ArrayList;

public class Converter {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("usage: java Converter.java <filename>");
        } else {
            // Open input file, read contents
            String contents = "";
            try {
                contents = new String(Files.readAllBytes(Paths.get(args[0])));
            } catch (IOException e) {
                e.printStackTrace();
                System.exit(1);
            }

            // Create Parser, parse document
            Parser parser = new Parser(contents);
            ArrayList<Node> html = parser.parseDocument();

            // Open output file, write out document
            try {
                FileWriter myWriter = new FileWriter("output.html");
                for (Node node : html) {
                    myWriter.write(node.getString());
                }
                myWriter.close();
              } catch (IOException e) {
                e.printStackTrace();
                System.exit(1);
              }
        }
    }
}