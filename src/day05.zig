const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day05.txt");
const example =
    \\    [D]    
    \\[N] [C]    
    \\[Z] [M] [P]
    \\ 1   2   3 
    \\
    \\move 1 from 2 to 1
    \\move 3 from 1 to 3
    \\move 2 from 2 to 1
    \\move 1 from 1 to 2
;

pub fn main() !void {
    const Input = struct {
        stacks: [][]u8,
        moves: [][]u8,
    };
    const input: Input = blk_input: {
        var iter = tokenize(u8, data, "\r\n");
        // var iter = tokenize(u8, example, "\r\n");

        // read the lines relavent to the stacks
        var stack_lines = List([]const u8).init(gpa);
        defer (stack_lines.deinit());
        var stack_count: usize = 0;
        while (iter.next()) |line| {
            if (0 < std.mem.count(u8, line, "[")) {
                try stack_lines.append(line);
            } else {
                var label_iter = tokenize(u8, line, " ");
                while (label_iter.next()) |_| {
                    stack_count += 1;
                }
                break;
            }
        }

        std.mem.reverse([]const u8, stack_lines.items);

        // populate stacks
        var stacks = List([]u8).init(gpa);
        try stacks.resize(stack_count);
        var index: usize = 1;
        for (stacks.items) |*stack| {
            var stack_temp = List(u8).init(gpa);
            for (stack_lines.items) |line| {
                const c = line[index];
                switch (c) {
                    ' ' => break,
                    'A'...'Z' => try stack_temp.append(c),
                    else => unreachable,
                }
            }
            stack.* = stack_temp.toOwnedSlice();
            index += 4;
        }

        // read the lines relavent to the moves
        var moves = List([]u8).init(gpa);
        while (iter.next()) |line| {
            var move_iter = tokenize(u8, line, "movefromto ");
            var move_list = List(u8).init(gpa);
            while (move_iter.next()) |s| {
                const n = try parseInt(u8, s, 10);
                try move_list.append(n);
            }
            assert(move_list.items.len == 3);
            try moves.append(move_list.toOwnedSlice());
        }

        break :blk_input .{ .stacks = stacks.toOwnedSlice(), .moves = moves.toOwnedSlice() };
    };

    // part 1
    {
        // create and populate stacks
        var stacks: []List(u8) = blk: {
            var stacks_list = List(List(u8)).init(gpa);
            for (input.stacks) |s| {
                var stack = try List(u8).initCapacity(gpa, 256);
                try stack.appendSlice(s);
                try stacks_list.append(stack);
            }
            break :blk stacks_list.toOwnedSlice();
        };

        // execute moves
        for (input.moves) |move| {
            assert(move.len == 3);
            const quantity = move[0];
            const from = move[1] - 1;
            const to = move[2] - 1;

            var count: usize = 0;
            while (count < quantity) : (count += 1) {
                const value = stacks[from].pop();
                try stacks[to].append(value);
            }
        }

        // peek at top of stacks
        for (stacks) |stack| {
            assert(stack.items.len > 0);
            const top = stack.items[stack.items.len - 1];
            print("{c}", .{top});
        }
        print("\n", .{});
    }

    // part 2
    {
        // create and populate stacks
        var stacks: []List(u8) = blk: {
            var stacks_list = List(List(u8)).init(gpa);
            for (input.stacks) |s| {
                var stack = try List(u8).initCapacity(gpa, 256);
                try stack.appendSlice(s);
                try stacks_list.append(stack);
            }
            break :blk stacks_list.toOwnedSlice();
        };

        // execute moves
        for (input.moves) |move| {
            assert(move.len == 3);
            const quantity = move[0];
            const from = move[1] - 1;
            const to = move[2] - 1;

            var count: usize = 0;
            var temp = List(u8).init(gpa);
            defer (temp.deinit());
            // pop off the stack into a temporary stack
            while (count < quantity) : (count += 1) {
                const value = stacks[from].pop();
                try temp.append(value);
            }
            // pop off the temporary stack onto the correct stack
            while (temp.popOrNull()) |value| {
                try stacks[to].append(value);
            }
        }

        // peek at top of stacks
        for (stacks) |stack| {
            assert(stack.items.len > 0);
            const top = stack.items[stack.items.len - 1];
            print("{c}", .{top});
        }
        print("\n", .{});
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
