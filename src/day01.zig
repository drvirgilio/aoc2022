const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");
const example =
    \\1000
    \\2000
    \\3000
    \\
    \\4000
    \\
    \\5000
    \\6000
    \\
    \\7000
    \\8000
    \\9000
    \\
    \\10000
;

pub fn main() !void {
    const Item = struct { index: u32, value: u32 };
    const input: []Item = blk: {
        var iter = split(u8, data, "\n");
        var list = List(Item).init(gpa);
        var index: u32 = 0;
        while (iter.next()) |s| {
            const st = trim(u8, s, "\r");
            if (st.len == 0) {
                // This is the end of the list for this particular elf
                // Increment index and go to next line
                index += 1;
            } else {
                const n = try parseInt(u32, st, 10);
                try list.append(.{ .index = index, .value = n });
            }
        }
        break :blk list.toOwnedSlice();
    };

    // part 1
    {
        // sum the items grouped by index
        var sums = List(u64).init(gpa);
        for (input) |item| {
            if (item.index >= sums.items.len) {
                try sums.append(item.value);
            } else {
                sums.items[sums.items.len - 1] += item.value;
            }
        }

        // find the maximum value
        var answer: u64 = 0;
        for (sums.items) |value| {
            answer = max(answer, value);
        }

        print("{}\n", .{answer});
    }

    // part 2
    {
        // sum the items grouped by index
        var sums = List(u64).init(gpa);
        for (input) |item| {
            if (item.index >= sums.items.len) {
                try sums.append(item.value);
            } else {
                sums.items[sums.items.len - 1] += item.value;
            }
        }

        // sort the sums
        sort(u64, sums.items, {}, comptime desc(u64));

        // sum the maximum 3 values
        var answer: u64 = 0;
        for (sums.items[0..3]) |value| {
            answer += value;
        }

        print("{}\n", .{answer});
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
