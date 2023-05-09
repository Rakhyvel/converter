const std = @import("std");
const Node = @import("nodes.zig").Node;

const Token = struct { data: []const u8, line: usize, col: usize };

pub const Parser = struct {
    index: u64,
    tokens: std.ArrayList(Token),

    pub fn init(contents: []u8, allocator: std.mem.Allocator) !Parser {
        var retval: Parser = Parser{ .index = 0, .tokens = std.ArrayList(Token).init(allocator) };

        var data: []u8 = contents[0..1];
        var line: usize = 1;
        var col: usize = 1;
        var oldCol: usize = 1;
        var oldC: u8 = contents[0];
        var i: usize = 1;
        while (i < contents.len) {
            var c = contents[i];
            if (oldC == '\n' or oldC == '\r' or (isSpecialChar(oldC) != isSpecialChar(c)) or c == '#' or c == '[' or c == '(' or c == '!' or c == '\n' or c == '\r') {
                if (!sliceContains(u8, data, '\r', byteEquals)) {
                    try retval.tokens.append(Token{ .data = data, .line = line, .col = oldCol });
                }
                oldCol = col + 1;
                if (c == '\n') {
                    line += 1;
                    col = 0;
                }
                data.ptr += data.len;
                while (oldC == '#' and data[0] < 32) {
                    i += 1;
                    data.ptr += 1;
                }
                data.len = 0;
            }
            i += 1;
            data.len += 1;
            col += 1;
            oldC = c;
        }
        try retval.tokens.append(Token{ .data = data, .line = line, .col = col });
        try retval.tokens.append(Token{ .data = "\n", .line = line, .col = col });
        return retval;
    }

    fn isSpecialChar(c: u8) bool {
        return c == '_' or
            c == '*' or
            c == '`' or
            c == '#' or
            c == '[' or
            c == ']' or
            c == '(' or
            c == ')' or
            c == '!';
    }

    fn sliceContains(comptime T: type, haystack: []T, needle: T, compare: *const fn (T, T) bool) bool {
        for (haystack) |c| {
            if (compare(c, needle)) {
                return true;
            }
        } else {
            return false;
        }
    }

    fn byteEquals(a: u8, b: u8) bool {
        return a == b;
    }

    fn stringEquals(a: []const u8, b: []const u8) bool {
        if (a.len != b.len) {
            return false;
        } else {
            var i: usize = 0;
            while (i < a.len) {
                if (a[i] != b[i]) {
                    return false;
                }
                i += 1;
            } else {
                return true;
            }
        }
    }

    pub fn parseDocument(self: *Parser, allocator: std.mem.Allocator) !std.ArrayList(Node) {
        var retval = std.ArrayList(Node).init(allocator);
        while (self.index < self.tokens.items.len - 1) {
            if (try self.parseNode(allocator)) |node| {
                try retval.append(node);
            }
        }
        return retval;
    }

    fn pop(self: *Parser) Token {
        self.index += 1;
        return self.tokens.items[self.index - 1];
    }

    fn peek(self: *Parser) Token {
        return self.tokens.items[self.index];
    }

    fn accept(self: *Parser, data: []const u8) ?Token {
        if (stringEquals(self.peek().data, data)) {
            return self.pop();
        } else {
            return null;
        }
    }

    fn expect(self: *Parser, data: []const u8) void {
        if (self.accept(data) == null) {
            var top = self.peek();
            if (isSpecialChar(top.data[0])) {
                std.log.err("error: {}:{} expected `{s}`, got `{s}`.", .{ top.line, top.col, data, top.data });
            } else {
                std.log.err("error: {}:{} expected `{s}`, got text.", .{ top.line, top.col, data });
            }
            std.process.exit(1);
        }
    }

    fn takeUntil(self: *Parser, sentinel: []const u8) []const u8 {
        var data: []const u8 = self.peek().data;
        var lastPtr = data.ptr;
        while (self.accept(sentinel) == null) {
            lastPtr = self.pop().data.ptr;
        }
        lastPtr = self.tokens.items[self.index - 1].data.ptr;
        data.len = @ptrToInt(lastPtr) - @ptrToInt(data.ptr);
        return data;
    }

    fn parseNode(self: *Parser, allocator: std.mem.Allocator) !?Node {
        if (self.accept("#") != null) {
            return try self.parseHeader(allocator);
        } else if (self.accept("```") != null) {
            return self.parseCodeBlock();
        } else if (self.accept("!") != null) {
            return self.parseImage();
        } else if (self.accept("\n") == null) {
            return try self.parseParagraph(allocator);
        } else {
            return null;
        }
    }

    fn parseHeader(self: *Parser, allocator: std.mem.Allocator) !Node {
        var size: usize = 1;
        while (self.accept("#") != null) {
            size += 1;
        }
        var bounds = std.ArrayList([]const u8).init(allocator);
        try bounds.append("\n");
        return Node{ .header = .{ .size = size, .children = try self.parseFormattedText(allocator, bounds) } };
    }

    fn parseParagraph(self: *Parser, allocator: std.mem.Allocator) !Node {
        var bounds = std.ArrayList([]const u8).init(allocator);
        try bounds.append("\n");
        return Node{ .paragraph = .{ .children = try self.parseFormattedText(allocator, bounds) } };
    }

    fn parseCodeBlock(self: *Parser) Node {
        return Node{ .codeblock = .{ .text = self.takeUntil("```") } };
    }

    fn parseImage(self: *Parser) Node {
        self.expect("[");
        var text = self.pop().data;
        self.expect("]");
        self.expect("(");
        var url = self.pop().data;
        self.expect(")");
        return Node{ .image = .{ .text = text, .url = url } };
    }

    fn parseItalic(self: *Parser, allocator: std.mem.Allocator, bounds: std.ArrayList([]const u8)) error{OutOfMemory}!Node {
        var newBounds = std.ArrayList([]const u8).init(allocator);
        for (bounds.items) |bound| {
            try newBounds.append(bound);
        }
        try newBounds.append("*");
        try newBounds.append("_");
        var children = try self.parseFormattedText(allocator, newBounds);
        if (self.accept("*") == null) {
            self.expect("_");
        }
        return Node{ .italic = .{ .children = children } };
    }

    fn parseBold(self: *Parser, allocator: std.mem.Allocator, bounds: std.ArrayList([]const u8)) error{OutOfMemory}!Node {
        var newBounds = std.ArrayList([]const u8).init(allocator);
        for (bounds.items) |bound| {
            try newBounds.append(bound);
        }
        try newBounds.append("**");
        try newBounds.append("__");
        var children = try self.parseFormattedText(allocator, newBounds);
        if (self.accept("**") == null) {
            self.expect("__");
        }
        return Node{ .bold = .{ .children = children } };
    }

    fn parseCode(self: *Parser) Node {
        return Node{ .code = .{ .text = self.takeUntil("`") } };
    }

    fn parseLink(self: *Parser) Node {
        var text = self.pop().data;
        self.expect("]");
        self.expect("(");
        var url = self.pop().data;
        self.expect(")");
        return Node{ .link = .{ .text = text, .url = url } };
    }

    fn parseFormattedText(self: *Parser, allocator: std.mem.Allocator, bounds: std.ArrayList([]const u8)) !std.ArrayList(Node) {
        var retval = std.ArrayList(Node).init(allocator);
        while (!sliceContains([]const u8, bounds.items, self.peek().data, stringEquals)) {
            if (self.accept("_") != null or self.accept("*") != null) {
                try retval.append(try self.parseItalic(allocator, bounds));
            } else if (self.accept("__") != null or self.accept("**") != null) {
                try retval.append(try self.parseBold(allocator, bounds));
            } else if (self.accept("`") != null) {
                try retval.append(self.parseCode());
            } else if (self.accept("[") != null) {
                try retval.append(self.parseLink());
            } else {
                try retval.append(Node{ .text = .{ .text = self.pop().data } });
            }
        }
        return retval;
    }
};
