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

    pub fn getHTML(node:Node, w:std.fs.File.Writer) void {
        switch (node) {
            NodeTag.header => {
                w.print("<h{}>", .{node.header.size}) catch unreachable;
                for (node.header.children.items) |child| {
                    getHTML(child, w);
                }
                w.print("</h{}>\n", .{node.header.size}) catch unreachable;
            },

            NodeTag.paragraph => {
                w.print("{s}", .{"<p>"}) catch unreachable;
                for (node.paragraph.children.items) |child| {
                    getHTML(child, w);
                }
                w.print("{s}", .{"</p>\n\n"}) catch unreachable;
            },

            NodeTag.codeblock => {
                w.print("{s}", .{"<pre><code>"}) catch unreachable;
                printCode(node.codeblock.text, w) catch unreachable;
                w.print("{s}", .{"</code></pre>\n\n"}) catch unreachable;
            },

            NodeTag.image => w.print("<img src=\"{s}\" alt=\"{s}\" />\n\n", .{node.image.url, node.image.text}) catch unreachable,

            NodeTag.text => w.print("{s}", .{node.text.text}) catch unreachable,

            NodeTag.italic => {
                w.print("{s}", .{"<em>"}) catch unreachable;
                for (node.italic.children.items) |child| {
                    getHTML(child, w);
                }
                w.print("{s}", .{"</em>"}) catch unreachable;
            },

            NodeTag.bold => {
                w.print("{s}", .{"<strong>"}) catch unreachable;
                for (node.bold.children.items) |child| {
                    getHTML(child, w);
                }
                w.print("{s}", .{"</strong>"}) catch unreachable;
            },

            NodeTag.code => {
                w.print("{s}", .{"<code>"}) catch unreachable;
                printCode(node.code.text, w) catch unreachable;
                w.print("{s}", .{"</code>"}) catch unreachable;
            },

            NodeTag.link => w.print("<a href=\"{s}\">{s}</a>", .{node.link.url, node.link.text}) catch unreachable,
        }
    }
};