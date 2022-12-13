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

    list: []*const Node,
    integer: usize,

    // pub fn print(self: Self, allocator: std.mem.Allocator) !void {
    pub fn print(self: *const Self) void {
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
        defer nodes.deinit();
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

    pub fn asc(context: void, left: *const Self, right: *const Self) bool {
        _ = context;
        return switch (left.order(right)) {
            .lt => true,
            .eq => false,
            .gt => false,
        };
    }

    pub fn order(left: *const Self, right: *const Self) std.math.Order {
        return switch (left.*) {
            .integer => |l| switch (right.*) {
                .integer => |r| std.math.order(l, r),
                .list => blk: {
                    var array: [1]*const Self = [1](*const Self){left};
                    const new_left = Self{ .list = &array };
                    break :blk new_left.order(right);
                },
            },
            .list => |l| switch (right.*) {
                .integer => blk: {
                    var array = [1]*const Self{right};
                    const new_right = Self{ .list = &array };
                    break :blk left.order(&new_right);
                },
                .list => |r| blk: {
                    const length = std.math.min(l.len, r.len);
                    var i: usize = 0;
                    while (i < length) : (i += 1) {
                        const compare = l[i].order(r[i]);
                        switch (compare) {
                            .eq => continue,
                            else => break :blk compare,
                        }
                    } else {
                        break :blk std.math.order(l.len, r.len);
                    }
                },
            },
        };
    }
};

pub fn main() !void {
    // part 1
    {
        // var lines = tokenize(u8, example, "\r\n");
        var lines = tokenize(u8, data, "\r\n");

        var index: usize = 1;
        var answer_1: usize = 0;
        while (lines.next()) |fst_line| : (index += 1) {
            const snd_line = lines.next().?;
            const fst_tokens = try Token.tokenize(gpa, fst_line);
            const snd_tokens = try Token.tokenize(gpa, snd_line);

            defer gpa.free(fst_tokens);
            defer gpa.free(snd_tokens);

            const fst_nodes = try Node.parseTokens(gpa, fst_tokens);
            const snd_nodes = try Node.parseTokens(gpa, snd_tokens);

            defer gpa.free(fst_nodes);
            defer gpa.free(snd_nodes);

            const fst = fst_nodes[fst_nodes.len - 1];
            const snd = snd_nodes[snd_nodes.len - 1];

            answer_1 += switch (fst.order(&snd)) {
                .lt => blk: {
                    break :blk index;
                },
                .gt => 0,
                .eq => unreachable,
            };
        }

        print("{d}\n", .{answer_1});
    }

    // part 2
    {
        // var lines = tokenize(u8, example, "\r\n");
        var lines = tokenize(u8, data, "\r\n");

        var roots = List(*const Node).init(gpa);
        defer roots.deinit();
        while (lines.next()) |line| {
            const tokens = try Token.tokenize(gpa, line);
            const nodes = try Node.parseTokens(gpa, tokens);
            const root = &nodes[nodes.len - 1];

            defer gpa.free(tokens);

            // this causes use-after-free bug because we give the memory to roots
            // instead this is a memory leak
            // TODO: find a way to free this memory outside the while loop
            // defer gpa.free(nodes);

            try roots.append(root);
        }

        // append divider packets
        // TODO: free this memory
        const p1_tokens = try Token.tokenize(gpa, "[[2]]");
        const p2_tokens = try Token.tokenize(gpa, "[[6]]");
        const p1_nodes = try Node.parseTokens(gpa, p1_tokens);
        const p2_nodes = try Node.parseTokens(gpa, p2_tokens);
        const p1 = &p1_nodes[p1_nodes.len - 1];
        const p2 = &p2_nodes[p2_nodes.len - 1];
        try roots.append(p1);
        try roots.append(p2);

        std.sort.sort(*const Node, roots.items, {}, comptime Node.asc);
        var answer_2: usize = 1;
        for (roots.items) |root, index| {
            if (root == p1) answer_2 *= index + 1;
            if (root == p2) answer_2 *= index + 1;
        }

        print("{d}\n", .{answer_2});
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
