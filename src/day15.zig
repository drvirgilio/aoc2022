const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day15.txt");
const example =
    \\Sensor at x=2, y=18: closest beacon is at x=-2, y=15
    \\Sensor at x=9, y=16: closest beacon is at x=10, y=16
    \\Sensor at x=13, y=2: closest beacon is at x=15, y=3
    \\Sensor at x=12, y=14: closest beacon is at x=10, y=16
    \\Sensor at x=10, y=20: closest beacon is at x=10, y=16
    \\Sensor at x=14, y=17: closest beacon is at x=10, y=16
    \\Sensor at x=8, y=7: closest beacon is at x=2, y=10
    \\Sensor at x=2, y=0: closest beacon is at x=2, y=10
    \\Sensor at x=0, y=11: closest beacon is at x=2, y=10
    \\Sensor at x=20, y=14: closest beacon is at x=25, y=17
    \\Sensor at x=17, y=20: closest beacon is at x=21, y=22
    \\Sensor at x=16, y=7: closest beacon is at x=15, y=3
    \\Sensor at x=14, y=3: closest beacon is at x=15, y=3
    \\Sensor at x=20, y=1: closest beacon is at x=15, y=3
;

const Point = struct {
    x: isize,
    y: isize,

    fn distance(a: Point, b: Point) usize {
        const dx = if (a.x > b.x) a.x - b.x else b.x - a.x;
        const dy = if (a.y > b.y) a.y - b.y else b.y - a.y;
        return @intCast(usize, dx) + @intCast(usize, dy);
    }
};

const Pair = struct {
    fst: Point,
    snd: Point,
};

pub fn main() !void {
    const input: []Pair = blk: {
        var list = List(Pair).init(gpa);

        var lines_it = tokenize(u8, example, "\r\n");
        // var lines_it = tokenize(u8, data, "\r\n");

        while (lines_it.next()) |line| {
            var parts_it = tokenize(u8, line, "Senor atx=,y:clsbci");
            const x0 = try parseInt(isize, parts_it.next().?, 10);
            const y0 = try parseInt(isize, parts_it.next().?, 10);
            const x1 = try parseInt(isize, parts_it.next().?, 10);
            const y1 = try parseInt(isize, parts_it.next().?, 10);
            // print("{d},{d}  {d},{d}\n", .{ x0, y0, x1, y1 });
            try list.append(Pair{ .fst = Point{ .x = x0, .y = y0 }, .snd = Point{ .x = x1, .y = y1 } });
        }

        break :blk list.toOwnedSlice();
    };

    // for each pair, find the ranges of filled values on the test line
    const test_line = 10;
    _ = test_line;
    for (input) |p| {
        print("{d},{d}  {d},{d}\n", .{ p.fst.x, p.fst.y, p.snd.x, p.snd.y });
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
