// To run: dotnet run ../input.md
// Pros:
//  - Very easy to setup a new project with command line, small project files
//  - Can have functions outside of classes, unlike Java (sorta)
//  - I like the Console.ReadKey() method, I could see myself using it if I was using VS Studio or if it was a console app
//  - File.ReadAllFile() is a good method
//  - Indexable arrays
//  - 'bool' boolean type identifier instead of 'boolean'
//  - Indexable lists ? (is this a pro? Maybe in an interpreted language...)
//  - Nullable types (though it's weakly enforced...)
//  - Formatted print with newline after
//  - Can have more than one public class in one file
//  - Readonly
//  - Stacktraces with positions to where exceptions were thrown, with error message
//  - Async await
// Cons:
//  - Weird global entry point system, and also a weird main function system? Why not just have one system
//  - PascalCase
//  - Namespaces cannot contain functions
//  - Slow to compile
//  - .csproj file is in XML
//  - Structures have too much boilerplate, same with classes. No logical implicit constructor for structs

class Converter {
    public static async Task Main(string[] args) {
        if (args.Length != 1) {
            Console.WriteLine("usage: dotnet run <filename>");
        } else {
            // Open input file, read contents
            string contents = File.ReadAllText(args[0]);

            // Create parser, parse Markdown document
            Parser parser = new Parser(contents);
            List<INode> html = parser.ParseDocument();

            // Open output file, write HTML document
            using StreamWriter file = new("output.html");
            foreach (INode node in html) {
                await file.WriteLineAsync(node.GetString());
            }
        }
    }
}