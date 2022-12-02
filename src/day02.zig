const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");
const example =
    \\A Y
    \\B X
    \\C Z
;

pub fn main() !void {
    const Fst = enum(u8) {
        A = 'A',
        B = 'B',
        C = 'C',
    };
    const Snd = enum(u8) {
        X = 'X',
        Y = 'Y',
        Z = 'Z',
    };
    const Round = struct { fst: Fst, snd: Snd };
    const input: []Round = blk: {
        var iter = tokenize(u8, data, "\r\n");
        // var iter = tokenize(u8, example, "\r\n");
        var list = List(Round).init(gpa);
        while (iter.next()) |s| {
            try list.append(.{
                .fst = @intToEnum(Fst, s[0]),
                .snd = @intToEnum(Snd, s[2]),
            });
        }
        break :blk list.toOwnedSlice();
    };

    // for (input) |round| {
    //     print("{}\n", .{round});
    // }

    // part 1
    {
        var score: u32 = 0;
        for (input) |round| {
            score += switch (round.snd) {
                // you choose rock
                .X => @as(u32, 1) + switch (round.fst) {
                    .A => @as(u32, 3), // rock
                    .B => @as(u32, 0), // paper
                    .C => @as(u32, 6), // scissors
                },
                // you choose paper
                .Y => @as(u32, 2) + switch (round.fst) {
                    .A => @as(u32, 6), // rock
                    .B => @as(u32, 3), // paper
                    .C => @as(u32, 0), // scissors
                },
                // you choose scissors
                .Z => @as(u32, 3) + switch (round.fst) {
                    .A => @as(u32, 0), // rock
                    .B => @as(u32, 6), // paper
                    .C => @as(u32, 3), // scissors
                },
            };
        }
        print("{}\n", .{score});
    }

    // part 2
    {
        var score: u32 = 0;
        for (input) |round| {
            score += switch (round.snd) {
                // you must lose
                .X => @as(u32, 0) + switch (round.fst) {
                    .A => @as(u32, 3), // scissors loses to rock
                    .B => @as(u32, 1), // rock loses to paper
                    .C => @as(u32, 2), // paper loses to scissors
                },
                // you must tie
                .Y => @as(u32, 3) + switch (round.fst) {
                    .A => @as(u32, 1), // rock
                    .B => @as(u32, 2), // paper
                    .C => @as(u32, 3), // scissors
                },
                // you must win
                .Z => @as(u32, 6) + switch (round.fst) {
                    .A => @as(u32, 2), // paper wins to rock
                    .B => @as(u32, 3), // scissors wins to paper
                    .C => @as(u32, 1), // rock wins to scissors
                },
            };
        }
        print("{}\n", .{score});
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
