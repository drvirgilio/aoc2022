const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");
const example =
    \\vJrwpWtwJgWrhcsFMMfFFhFp
    \\jqHRNqRjqzjGDLGLrsFMfFZSrLrFZsSL
    \\PmmdzqPrVvPwwTWBwg
    \\wMqvLMZHhHMvwLHjbvcjnnSBnvTQFn
    \\ttgJtRGJQctTZtZT
    \\CrZsJsPPZsGzwwsLwLmpwMDw
;

pub fn main() !void {

    // part 1
    {
        const input: [][]const u8 = blk: {
            var iter = tokenize(u8, data, "\r\n");
            //var iter = tokenize(u8, example, "\r\n");
            var list = List([]const u8).init(gpa);
            while (iter.next()) |s| {
                try list.append(s);
            }
            break :blk list.toOwnedSlice();
        };

        var answer: u32 = 0;
        for (input) |bag| {
            // each compartment is a set of u8
            var set_fst = try BitSet.initEmpty(gpa, std.math.maxInt(u8));
            var set_snd = try BitSet.initEmpty(gpa, std.math.maxInt(u8));

            // populate sets
            for (bag[0 .. bag.len / 2]) |item| {
                set_fst.set(item);
            }
            for (bag[bag.len / 2 .. bag.len]) |item| {
                set_snd.set(item);
            }

            // intersection stored in first set
            set_fst.setIntersection(set_snd);

            // calculate priority and add it to answer
            var iter = set_fst.iterator(.{});
            while (iter.next()) |index| {
                const item = @intCast(u8, index);
                const item_priority = switch (item) {
                    'a'...'z' => item - 'a' + 1,
                    'A'...'Z' => item - 'A' + 27,
                    else => unreachable,
                };
                answer += item_priority;
            }
        }

        print("{d}\n", .{answer});
    }

    // part 2
    {
        const Group = struct {
            fst: []const u8,
            snd: []const u8,
            thd: []const u8,
        };
        const input: []Group = blk: {
            var iter = tokenize(u8, data, "\r\n");
            //var iter = tokenize(u8, example, "\r\n");
            var list = List(Group).init(gpa);
            while (iter.next()) |fst| {
                const snd = iter.next().?;
                const thd = iter.next().?;
                try list.append(.{
                    .fst = fst,
                    .snd = snd,
                    .thd = thd,
                });
            }
            break :blk list.toOwnedSlice();
        };

        var answer: u32 = 0;
        for (input) |group| {
            // each elf in the group is carrying a set of item types
            var set_fst = try BitSet.initEmpty(gpa, std.math.maxInt(u8));
            var set_snd = try BitSet.initEmpty(gpa, std.math.maxInt(u8));
            var set_thd = try BitSet.initEmpty(gpa, std.math.maxInt(u8));

            // populate sets
            for (group.fst) |item| {
                set_fst.set(item);
            }
            for (group.snd) |item| {
                set_snd.set(item);
            }
            for (group.thd) |item| {
                set_thd.set(item);
            }

            // intersection stored in first set
            set_fst.setIntersection(set_snd);
            set_fst.setIntersection(set_thd);

            // calculate priority and add it to answer
            var iter = set_fst.iterator(.{});
            while (iter.next()) |index| {
                const item = @intCast(u8, index);
                const item_priority = switch (item) {
                    'a'...'z' => item - 'a' + 1,
                    'A'...'Z' => item - 'A' + 27,
                    else => unreachable,
                };
                answer += item_priority;
            }
        }

        print("{d}\n", .{answer});
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
