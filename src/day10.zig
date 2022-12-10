const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day10.txt");
const Operation = enum { noop, addx };
const Instruction = union(Operation) {
    noop: void,
    addx: isize,
};

pub fn main() !void {
    const input: []Instruction = blk: {
        var list = List(Instruction).init(gpa);
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            switch (line[0]) {
                'n' => try list.append(Instruction{ .noop = .{} }),
                'a' => try list.append(Instruction{ .addx = try parseInt(isize, line[5..], 10) }),
                else => unreachable,
            }
        }
        break :blk list.toOwnedSlice();
    };

    print("part 2:\n", .{});

    var answer_1: isize = 0;
    var clk: isize = 0; // using 0-indexing instead of 1-indexing
    var x: isize = 1;
    for (input) |inst| {
        switch (inst) {
            .noop => {
                display(clk, x);
                answer_1 += signal_strenth(clk, x);
                clk += 1;

                continue;
            },
            .addx => |amount| {
                display(clk, x);
                answer_1 += signal_strenth(clk, x);
                clk += 1;

                display(clk, x);
                answer_1 += signal_strenth(clk, x);
                clk += 1;

                x += amount;
                continue;
            },
        }
    }

    print("part 1: {}\n", .{answer_1});
}

fn display(clk: isize, x: isize) void {
    const pixel = @mod(clk, 40);
    switch (x - pixel) {
        -1, 0, 1 => print("#", .{}),
        else => print(" ", .{}),
    }
    if (pixel == 39) print("\n", .{});
}

fn signal_strenth(clk: isize, x: isize) isize {
    return if (@mod(clk, 40) == 19)
        (clk + 1) * x
    else
        0;
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
