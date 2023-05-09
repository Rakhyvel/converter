const std = @import("std");

pub const Node = union(enum) {
    header: struct { size: usize, children: std.ArrayList(Node) },

    paragraph: struct { children: std.ArrayList(Node) },

    codeblock: struct { text: []const u8 },

    image: struct { text: []const u8, url: []const u8 },

    text: struct { text: []const u8 },

    italic: struct { children: std.ArrayList(Node) },

    bold: struct { children: std.ArrayList(Node) },

    code: struct { text: []const u8 },

    link: struct { text: []const u8, url: []const u8 },

    fn printCode(text: []const u8, w: std.fs.File.Writer) !void {
        for (text) |c| {
            if (c != '\r') {
                try w.print("{c}", .{c});
            }
        }
    }

    pub fn getHTML(node: Node, w: std.fs.File.Writer) !void {
        switch (node) {
            .header => {
                try w.print("<h{}>", .{node.header.size});
                for (node.header.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("</h{}>\n", .{node.header.size});
            },

            .paragraph => {
                try w.print("{s}", .{"<p>"});
                for (node.paragraph.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("{s}", .{"</p>\n\n"});
            },

            .codeblock => {
                try w.print("{s}", .{"<pre><code>"});
                try printCode(node.codeblock.text, w);
                try w.print("{s}", .{"</code></pre>\n\n"});
            },

            .image => try w.print("<img src=\"{s}\" alt=\"{s}\" />\n\n", .{ node.image.url, node.image.text }),

            .text => try w.print("{s}", .{node.text.text}),

            .italic => {
                try w.print("{s}", .{"<em>"});
                for (node.italic.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("{s}", .{"</em>"});
            },

            .bold => {
                try w.print("{s}", .{"<strong>"});
                for (node.bold.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("{s}", .{"</strong>"});
            },

            .code => {
                try w.print("{s}", .{"<code>"});
                try printCode(node.code.text, w);
                try w.print("{s}", .{"</code>"});
            },

            .link => try w.print("<a href=\"{s}\">{s}</a>", .{ node.link.url, node.link.text }),
        }
    }
};
