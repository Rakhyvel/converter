// To run: cargo run
// Pros:
//  - AMAZING documentation and tutorial and lang server
//  - Optional data types
//  - Result data types
//  - Can declare functions in any order
//  - Really good compiler error messages! I like how it provides suggestions on how to fix an error, and they're usually correct
//  - dbg!() macro is useful
//  - todo!() macro is useful
//  - Good local var declaration syntax
//  - Immutability
//  - Warning if an identifier is the wrong style (ie camelCase when it should be snake_case)
//  - Compiler suggests lexically close identifiers if an identifier isn't found
//  - Panics provide source code location
//  - Runtime parametric polymorphism with traits
//  - Blocks return last expression evaluated
//  - Good syntax for enum literals
//  - Pattern matching
//  - if let idiom
//  - Iterable for loop
//  - Warning if a local variable is never used, if a function is never called
//  - Good string formatting
// Cons:
//  - Cargo is a bit bulky and sensitive. Not suitable for prototyping
//  - File hierarchy and modules are non-intuitive
//  - Lifetimes are complicated (very clever but still too complicated)
//      (lifetime poisoning)
//  - Getting a simple immutable String slice should probably be easier...
//  - I get that the borrow checker is probably correct, but it's still very annoying
//      (I'd rather it be subtractive than additive)
//      (I'd rather it say "I can prove this is incorrect, so this is an error" rather than "I can't prove this is correct, so this is an error")
//      (reference poisoning)
//  - Grammar sometimes doens't alllow positional struct literals? Why
//  - Implicit MANUAL memory management makes it hard to explicitly know what's really going on with memory. Either have explicit manual memory management or implicit automatic memory management.
//      (I would rather prototype a program that leaks memory that I can easily go back and fix rather than struggle to write a perfect program on my first attempt)
//      (Goes against accretion-driven development)
//  - not a big fan of public/private for structs. Structs are just data
//  - no 'int' type, have to choose a size. Semantically I want to convey "this variable is just a number". Labelling it with a size implies some thought and intention went into choosing the size, when 99% of the time I just want an integer.
//  - Need commas in between struct field declarations, even if they span lines

mod parser;
mod nodes;

use std::env;
use std::fs::File;
use std::io::prelude::*;
use std::path::Path;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        panic!("usage: cargo run <filename>");
    }

    let filename = &args[1];

    // Create a path to the desired file
    let path = Path::new(filename);
    let display = path.display();

    // Open the path in read-only mode, returns `io::Result<File>`
    let mut file = match File::open(&path) {
        Err(why) => panic!("couldn't open {}: {}", display, why),
        Ok(file) => file,
    };

    // Read the file contents into a string, returns `io::Result<usize>`
    let mut s = String::new();
    match file.read_to_string(&mut s) {
        Err(why) => panic!("couldn't read {}: {}", display, why),
        Ok(_) => (),
    }

    let mut _parser = parser::create_parser(s);
    let html = _parser.parse_document();

    let path = Path::new("output.html");
    let display = path.display();

    // Open a file in write-only mode, returns `io::Result<File>`
    let mut file = match File::create(&path) {
        Err(why) => panic!("couldn't create {}: {}", display, why),
        Ok(file) => file,
    };

    for node in html.iter() {
        match file.write_all(node.get_string().as_bytes()) {
            Ok(_) => (),
            Err(_) => panic!("Error writing to output file")
        }
    }
}