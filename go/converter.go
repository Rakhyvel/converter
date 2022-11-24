package main

// To run: go run . ../input.md
// Pros:
//	- Has defer (but runs at end of function)
//	- I like the "declared but not used" errors actually
//	- Can put functions anywhere
//	- Type inference
//	- Functions must return value in all control paths
//	- I think the compiler comes with a formatter, which is neat
//	- == to compare string equality
//	- Multiple return is still pretty cool
//	- Cool compile warnings about loops where the condition doesn't change
//	- Sensical if-let, for-let idiom (VERY COOL!)
//	- immutable strings
//	- slices function like lists, have good support
//	- implicit dereference through dots
//	- Methods are defined outside of struct definitions
// 	- Good string concat syntax
//	- Interfaces are good!
//	- Package manager is actually pretty sick when you can just say `import "url.com"` and it'll import it into your project no fiddling required
//	- Don't need semicolons
// Cons:
//	- Build system is a little clunky, don't like that I NEED to have a package setup
//  - Seems really slow to compile
//  - I don't like the public/private model based on case
//	- Weird way to get the command line arguments, like in Python
// 	- Checking return values is not my cup of tea for error handling, doesn't gaurantee error handling
//	- Disharmonious variable declaration syntax
//	- Defer can only be used to call functions, called at the end of this function
//	- Lol no generics
//	- Cannot chain expressions over more than one line the mathematically correct way
//	- Nil values rather than optionals
//	- HORRIBLE C pointer type syntax
//	- Slices don't have a length field like they should
//	- Strange memory model. Have to worry about UAF and other issues that come with pointers, but there's a garbage collector too? Weird. IDK where structs or variables are stored.
//
//
// Not a language thing but the VS lang server for Go is too eager with marking things as errors as I'm typing, and the formatting is annoying

import (
	"fmt"
	"os"
)

func main() {
	content, err := os.ReadFile(os.Args[1]) // the file is inside the local directory
	if err != nil {
		fmt.Println("Err")
	}
	parser := createParser(content)
	nodes := parser.parseDocument()
	f, err := os.Create("output.html") // creates a file at current directory
	if err != nil {
		fmt.Println(err)
	}
	for i := 0; i < len(nodes); i += 1 {
		f.WriteString(nodes[i].str())
	}
}
