const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day13.txt");
const example =
    \\[1,1,3,1,1]
    \\[1,1,5,1,1]
    \\
    \\[[1],[2,3,4]]
    \\[[1],4]
    \\
    \\[9]
    \\[[8,7,6]]
    \\
    \\[[4,4],4,4]
    \\[[4,4],4,4,4]
    \\
    \\[7,7,7,7]
    \\[7,7,7]
    \\
    \\[]
    \\[3]
    \\
    \\[[[]]]
    \\[[]]
    \\
    \\[1,[2,[3,[4,[5,6,7]]]],8,9]
    \\[1,[2,[3,[4,[5,6,0]]]],8,9]
;

const TokenType = enum { left_bracket, right_bracket, integer };
const Token = union(TokenType) {
    const Self = @This();

    left_bracket: void,
    right_bracket: void,
    integer: usize,

    pub fn tokenize(allocator: std.mem.Allocator, input: []const u8) ![]Self {
        var list = List(Token).init(allocator);
        //var depth: usize = 0;
        var i: usize = 0;
        while (i < input.len) : (i += 1) {
            const this: u8 = input[i];
            const prev: ?u8 = if (i > 0) input[i - 1] else null;

            switch (this) {
                '[' => {
                    assert(if (prev) |p| p == ',' or p == '[' else true);
                    try list.append(TokenType.left_bracket);
                },
                ']' => {
                    assert(if (prev) |p| (p >= '0' and p <= '9') or p == '[' or p == ']' else false);
                    try list.append(TokenType.right_bracket);
                },
                '0'...'9' => {
                    assert(if (prev) |p| (p >= '0' and p <= '9') or p == '[' or p == ',' else false);
                    const next = input[i + 1];
                    switch (next) {
                        '0'...'9' => {
                            // integers are a max of two bytes so if the second byte is a digit, parse the integer and skip the next byte
                            const n = try parseInt(usize, input[i .. i + 2], 10);
                            try list.append(Token{ .integer = n });
                            i += 1;
                        },
                        else => {
                            try list.append(Token{ .integer = this - '0' });
                        },
                    }
                },
                ',' => {
                    assert(if (prev) |p| (p >= '0' and p <= '9') or p == ']' else false);
                },
                else => unreachable,
            }
        }
        return list.toOwnedSlice();
    }
};

const NodeType = enum { list, integer };
const Node = union(NodeType) {
    const Self = @This();

    list: []*Node,
    integer: usize,

    // pub fn print(self: Self, allocator: std.mem.Allocator) !void {
    pub fn print(self: *const Self) void {
        // var stack = List(Self).init(allocator);
        switch (self.*) {
            .integer => |n| std.debug.print(" {d} ", .{n}),
            .list => |nodes| {
                std.debug.print("[", .{});
                for (nodes) |*node| {
                    node.*.print();
                }
                std.debug.print("]", .{});
            },
        }
    }

    /// last node in the output slice is the root node
    fn parseTokens(allocator: std.mem.Allocator, tokens: []Token) ![]const Self {
        var nodes = try List(Self).initCapacity(allocator, tokens.len);
        //defer nodes.deinit();
        var stack = List(List(*Self)).init(allocator);
        defer stack.deinit();
        var i: usize = 0;
        while (i < tokens.len) : (i += 1) {
            switch (tokens[i]) {
                .left_bracket => {
                    // std.debug.print("[", .{});
                    // push new list onto stack
                    try stack.append(List(*Self).init(allocator));
                },
                .right_bracket => {
                    // std.debug.print("]", .{});
                    // pop list off stack, create list node, commit it to nodes list, and add pointer to list on top of stack (parent)
                    // var list: List(*Self) = try stack.pop().clone();
                    // const node = Node{ .list = list.toOwnedSlice() };
                    const node = Node{ .list = (try stack.pop().clone()).toOwnedSlice() };
                    try nodes.append(node);
                    if (stack.items.len > 0) {
                        const ptr = &nodes.items[nodes.items.len - 1];
                        try stack.items[stack.items.len - 1].append(ptr);
                    } else break;
                },
                .integer => |n| {
                    // std.debug.print(" {} ", .{n});
                    // append new node to nodes list and append its pointer to the list on the top of the stack
                    try nodes.append(Self{ .integer = n });
                    const ptr = &nodes.items[nodes.items.len - 1];
                    try stack.items[stack.items.len - 1].append(ptr);
                },
            }
        }
        // std.debug.print("\n", .{});
        return nodes.toOwnedSlice();
    }
};

pub fn main() !void {
    var lines = tokenize(u8, example, "\r\n");
    // var lines = tokenize(u8, data, "\r\n");

    while (lines.next()) |fst_line| {
        const snd_line = lines.next().?;
        const fst_tokens = try Token.tokenize(gpa, fst_line);
        const snd_tokens = try Token.tokenize(gpa, snd_line);

        const fst_nodes = try Node.parseTokens(gpa, fst_tokens);
        const snd_nodes = try Node.parseTokens(gpa, snd_tokens);

        const fst = fst_nodes[fst_nodes.len - 1];
        const snd = snd_nodes[snd_nodes.len - 1];

        fst.print();
        print("\n", .{});
        snd.print();
        print("\n\n", .{});
    }
}

// Useful stdlib functions
const tokenize = std.mem.tokenize;
const split = std.mem.split;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const min = std.math.min;
const min3 = std.math.min3;
const max = std.math.max;
const max3 = std.math.max3;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.sort;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
