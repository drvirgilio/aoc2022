const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day06.txt");
const example = "nznrnfrfntjfmvfwmzdfjlvtqnbhcprsg";

pub fn main() !void {
    const input = data;
    // const input = example;

    var answer_1: usize = undefined;
    var answer_2: usize = undefined;

    // part 1
    {
        const window = 4;
        var index: usize = window;
        var bitset = std.bit_set.IntegerBitSet(26).initEmpty();
        while (bitset.count() != window) : (index += 1) {
            assert(index < input.len);
            bitset.mask = 0;
            for (input[index - window .. index]) |char| {
                bitset.set(char - 'a');
            }
        }
        answer_1 = index - 1;
    }

    // part 2
    {
        const window = 14;
        var index: usize = window;
        var bitset = std.bit_set.IntegerBitSet(26).initEmpty();
        while (bitset.count() != window) : (index += 1) {
            assert(index < input.len);
            bitset.mask = 0;
            for (input[index - window .. index]) |char| {
                bitset.set(char - 'a');
            }
        }
        answer_2 = index - 1;
    }

    print("{d}\n", .{answer_1});
    print("{d}\n", .{answer_2});
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
