// To run: zig build run
// Pros:
//  - Really well put together OOBE, package manager is well thought out, everything is just good.
//  - Tests detect memory leaks
//  - Immutability
//  - Defer (which runs correctly at the end of the block!)
//  - Build script is in Zig
//  - Unused return values, can be escaped by assigning to _ (_ is consequently a reseved word)
//  - @ to escape reserved words
//  - First class types
//  - Compile time evaluation based generics
//  - Allocators
//  - Foreach
//  - Assignment isn't an expression
//  - Compile objects are cached (I think line by line, which is cool)
//  - Can compile C code
//  - Built-in testing
//  - Logging
// Cons:
//  - Weird print statement syntax, can't just print a string, need to wrap everything in a struct.
//  - Long qualified name for standard out print function
//  - Args are in an iterator rather than just a straight up string array. Weird.
//  - Little presence on StackOverflow. Doesn't exist.
//  - Semicolons after structs
//  - Parenthesis around if while for
//  - Little documentation, tutorials cover the basics of PROGRAMMING and not much else
//  - Concept of public/private
//  - Surprisingly doesn't tell you where in YOUR code a segmentation fault occurs in. Not helpful!
//  - Unions aren't tagged by default
//  - No std library support for strings (surprising really)
//  - I know I already said this but: THERE IS NO DOCUMENTATION. It is IMPOSSIBLE to find out ANYTHING about this language. NOTHING IN ZIG IS INTUITIVE. I'm absolutely disappointed.
//  - Error messages for macros only have source code positions for where the macro is defined. No way to know where in your code the error comes from. (sometimes it does sometimes it doesn't. Should always have it)
//  - Cannot convert addresses and 64 bit integers. This is a well defined operation. It make sense to do this. You should be able to do this. This is something that you should be able to do.
//
//  Lang server is trash. Rarely tells me the types, low explorability, everything is so opaque. Lang server doesn't emit errors. Probably because compilation is so complicated, even the front end.

const std = @import("std");
const parser = @import("parser.zig");

pub fn main() !void {
    // Get second command line argument
    const allocator = std.heap.page_allocator;
    var args = try std.process.ArgIterator.initWithAllocator(allocator);
    _ = args.next() orelse unreachable;
    var arg = args.next() orelse {
        std.debug.print("{s}\n", .{"Usage: zig build run -- <markdown-filename>"});
        return;
    };

    // Get the path
    var path_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const path = try std.fs.realpath(arg, &path_buffer);

    // Open the file
    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();
    
    // Read the contents
    const buffer_size = 2000;
    const file_buffer = try file.readToEndAlloc(allocator, buffer_size);
    defer allocator.free(file_buffer);

    // Create the parser, parse document
    var p:parser.Parser = try parser.Parser.init(file_buffer, allocator);
    var document = p.parseDocument(allocator);

    // Open the output file, write out document
    const outputFile = try std.fs.cwd().createFile(
        "output.html",
        .{ .read = true },
    );
    defer outputFile.close();

    for (document.items) |node| {
        node.getHTML(outputFile.writer());
    }
}