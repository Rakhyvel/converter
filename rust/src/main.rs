// To run: cargo run ../input.md
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
//  - Functional programming patterns
// Cons:
//  - Cargo is a bit bulky and sensitive. Not suitable for prototyping
//      (Just for this project the rust directory is 11 MEGABYTES. 20 times larger than others)
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
use std::result::Result;
use std::error::Error;

fn main()->Result<(), Box<dyn Error>> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 2 {
        panic!("usage: cargo run <filename>");
    }

    // Open input file, read contents
    let mut file = File::open(&Path::new(&args[1]))?;
    let mut s = String::new();
    file.read_to_string(&mut s)?;

    // Create parser, parse document
    let mut _parser = parser::create_parser(s);
    let html = _parser.parse_document();

    // Open output file, write output
    let mut output_file = File::create(&Path::new("output.html"))?;
    for node in html.iter() {
        output_file.write_all(node.get_string().as_bytes())?
    }

    Ok(())
}