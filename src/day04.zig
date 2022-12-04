const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day04.txt");
const example =
    \\2-4,6-8
    \\2-3,4-5
    \\5-7,7-9
    \\2-8,3-7
    \\6-6,4-6
    \\2-6,4-8
;

pub fn main() !void {
    const input: [][4]u8 = blk: {
        var iter = tokenize(u8, data, "\r\n");
        //var iter = tokenize(u8, example, "\r\n");
        var list = List([4]u8).init(gpa);
        while (iter.next()) |line| {
            var nums_str = tokenize(u8, line, "-,");
            var nums: [4]u8 = undefined;
            nums[0] = try parseInt(u8, nums_str.next().?, 10);
            nums[1] = try parseInt(u8, nums_str.next().?, 10);
            nums[2] = try parseInt(u8, nums_str.next().?, 10);
            nums[3] = try parseInt(u8, nums_str.next().?, 10);
            try list.append(nums);
        }
        break :blk list.toOwnedSlice();
    };

    var answer_1: u32 = 0;
    var answer_2: u32 = 0;
    for (input) |nums| {
        // each elf in the pair is assigned to a set of sections
        var fst = try BitSet.initEmpty(gpa, 100);
        var snd = try BitSet.initEmpty(gpa, 100);
        var result = try BitSet.initEmpty(gpa, 100);

        // populate sets
        fst.setRangeValue(.{ .start = nums[0], .end = nums[1] + 1 }, true);
        snd.setRangeValue(.{ .start = nums[2], .end = nums[3] + 1 }, true);

        // if the union of two sets is equal to one of the two sets, then one set is a subset of the other
        result.setUnion(fst);
        result.setUnion(snd);
        var iter = result.iterator(.{});
        var all_set_fst = true;
        var all_set_snd = true;
        while (iter.next()) |section| {
            if (!fst.isSet(section)) {
                all_set_fst = false;
            }
            if (!snd.isSet(section)) {
                all_set_snd = false;
            }
        }

        if (all_set_fst or all_set_snd) {
            answer_1 += 1;
            //print("{}-{},{}-{}\n",.{nums[0],nums[1],nums[2],nums[3]});
        }

        // if the intersection is not empty, the sets overlap
        // intersection is stored in first set
        fst.setIntersection(snd);
        if (fst.count() != 0) {
            answer_2 += 1;
        }
    }

    print("{}\n", .{answer_1});
    print("{}\n", .{answer_2});
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
