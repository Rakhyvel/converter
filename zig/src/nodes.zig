const std = @import("std");

const NodeTag = enum {
    header,
    paragraph,
    codeblock,
    image,
    text,
    italic,
    bold,
    code,
    link
};

pub const Node = union(NodeTag) {
    header: struct {
        size:usize, 
        children:std.ArrayList(Node)
    },

    paragraph: struct {
        children:std.ArrayList(Node)
    },

    codeblock: struct {
        text:[]const u8
    },

    image: struct {
        text:[]const u8,
        url:[]const u8
    },

    text: struct {
        text:[]const u8
    },

    italic: struct {
        children:std.ArrayList(Node)
    },

    bold: struct {
        children:std.ArrayList(Node)
    },

    code: struct {
        text:[]const u8
    },

    link: struct {
        text:[]const u8,
        url:[]const u8
    },

    fn printCode(text:[]const u8, w:std.fs.File.Writer) !void {
        for (text) |c| {
            if (c != '\r') {
                try w.print("{c}", .{c});
            }
        }
    }

    pub fn getHTML(node:Node, w:std.fs.File.Writer) !void {
        switch (node) {
            NodeTag.header => {
                try w.print("<h{}>", .{node.header.size});
                for (node.header.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("</h{}>\n", .{node.header.size});
            },

            NodeTag.paragraph => {
                try w.print("{s}", .{"<p>"});
                for (node.paragraph.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("{s}", .{"</p>\n\n"});
            },

            NodeTag.codeblock => {
                try w.print("{s}", .{"<pre><code>"});
                try printCode(node.codeblock.text, w);
                try w.print("{s}", .{"</code></pre>\n\n"});
            },

            NodeTag.image => try w.print("<img src=\"{s}\" alt=\"{s}\" />\n\n", .{node.image.url, node.image.text}),

            NodeTag.text => try w.print("{s}", .{node.text.text}),

            NodeTag.italic => {
                try w.print("{s}", .{"<em>"});
                for (node.italic.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("{s}", .{"</em>"});
            },

            NodeTag.bold => {
                try w.print("{s}", .{"<strong>"});
                for (node.bold.children.items) |child| {
                    try getHTML(child, w);
                }
                try w.print("{s}", .{"</strong>"});
            },

            NodeTag.code => {
                try w.print("{s}", .{"<code>"});
                try printCode(node.code.text, w);
                try w.print("{s}", .{"</code>"});
            },

            NodeTag.link => try w.print("<a href=\"{s}\">{s}</a>", .{node.link.url, node.link.text}),
        }
    }
};