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

    fn distance(self: Pair) usize {
        return Point.distance(self.fst, self.snd);
    }

    // find if there is overlap between two 2D ranges (inclusive on both sides)
    fn range_overlap(a: Pair, b: Pair) bool {
        assert(a.fst.x <= a.snd.x); // range invalid: require fst < snd in both dimensions
        assert(a.fst.y <= a.snd.y); // range invalid: require fst < snd in both dimensions
        assert(b.fst.x <= b.snd.x); // range invalid: require fst < snd in both dimensions
        assert(b.fst.y <= b.snd.y); // range invalid: require fst < snd in both dimensions

        const a_fst_overlap_y: bool = b.fst.y <= a.fst.y and a.fst.y <= b.snd.y;
        const a_snd_overlap_y: bool = b.fst.y <= a.snd.y and a.snd.y <= b.snd.y;
        const b_fst_overlap_y: bool = a.fst.y <= b.fst.y and b.fst.y <= a.snd.y;
        const b_snd_overlap_y: bool = a.fst.y <= b.snd.y and b.snd.y <= a.snd.y;
        const overlap_y: bool = a_fst_overlap_y or a_snd_overlap_y or b_fst_overlap_y or b_snd_overlap_y;

        const a_fst_overlap_x: bool = b.fst.x <= a.fst.x and a.fst.x <= b.snd.x;
        const a_snd_overlap_x: bool = b.fst.x <= a.snd.x and a.snd.x <= b.snd.x;
        const b_fst_overlap_x: bool = a.fst.x <= b.fst.x and b.fst.x <= a.snd.x;
        const b_snd_overlap_x: bool = a.fst.x <= b.snd.x and b.snd.x <= a.snd.x;
        const overlap_x: bool = a_fst_overlap_x or a_snd_overlap_x or b_fst_overlap_x or b_snd_overlap_x;

        return overlap_y and overlap_x;
    }

    // merge two overlapping 1D ranges (inclusive on both sides)
    fn range_merge(a: Pair, b: Pair) Pair {
        const x_constant: bool = a.fst.x == a.snd.x and b.fst.x == b.snd.x;
        const y_constant: bool = a.fst.y == a.snd.y and b.fst.y == b.snd.y;
        assert(x_constant or y_constant); // ranges must be one dimensional
        assert(range_overlap(a, b)); // ranges must overlap

        if (x_constant) {
            const x = a.fst.x;
            const y0 = min(a.fst.y, b.fst.y);
            const y1 = max(a.snd.y, b.snd.y);
            const fst = Point{ .x = x, .y = y0 };
            const snd = Point{ .x = x, .y = y1 };
            return Pair{ .fst = fst, .snd = snd };
        } else if (y_constant) {
            const y = a.fst.y;
            const x0 = min(a.fst.x, b.fst.x);
            const x1 = max(a.snd.x, b.snd.x);
            const fst = Point{ .x = x0, .y = y };
            const snd = Point{ .x = x1, .y = y };
            return Pair{ .fst = fst, .snd = snd };
        } else unreachable;
    }

    // count the number of items in a range (inclusive on both sides)
    fn range_count(self: Pair) usize {
        const dx = self.snd.x - self.fst.x + 1;
        const dy = self.snd.y - self.fst.y + 1;
        const d = dx * dy;
        return @intCast(usize, d);
    }

    fn range_contains(self: Pair, point: Point) bool {
        assert(self.fst.x <= self.snd.x); // range invalid: require fst < snd in both dimensions
        assert(self.fst.y <= self.snd.y); // range invalid: require fst < snd in both dimensions

        const contained_x: bool = self.fst.x <= point.x and point.x <= self.snd.x;
        const contained_y: bool = self.fst.y <= point.y and point.y <= self.snd.y;

        return contained_x and contained_y;
    }
};

pub fn main() !void {
    const input: []Pair = blk: {
        var list = List(Pair).init(gpa);

        // var lines_it = tokenize(u8, example, "\r\n");
        var lines_it = tokenize(u8, data, "\r\n");

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

    // part 1
    {
        // for each pair, find the ranges of filled values on the test line
        const test_line = 2000000;
        var ranges = List(Pair).init(gpa);
        defer ranges.deinit();
        for (input) |p| {
            // print("{d},{d}  {d},{d}\n", .{ p.fst.x, p.fst.y, p.snd.x, p.snd.y });

            const dist_beacon_to_sensor = @intCast(isize, p.distance());
            const dist_line_to_sensor = if (test_line > p.fst.y) test_line - p.fst.y else p.fst.y - test_line;
            const difference = if (dist_beacon_to_sensor >= dist_line_to_sensor)
                dist_beacon_to_sensor - dist_line_to_sensor
            else
                continue;
            //const total_in_line = difference * 2 + 1;

            const left = Point{ .x = p.fst.x - difference, .y = test_line };
            const right = Point{ .x = p.fst.x + difference, .y = test_line };
            assert(left.distance(p.fst) == dist_beacon_to_sensor);
            assert(right.distance(p.fst) == dist_beacon_to_sensor);
            const range: Pair = Pair{ .fst = left, .snd = right };

            try ranges.append(range);

            // print("  beacon to sensor: {d}\n", .{dist_beacon_to_sensor});
            // print("  line to sensor  : {d}\n", .{dist_line_to_sensor});
            // print("  difference      : {d}\n", .{difference});
            // print("  range: {d},{d}  {d},{d}\n", .{ range.fst.x, range.fst.y, range.snd.x, range.snd.y });
            // print("  count: {d}\n", .{range.range_count()});
        }

        // merge ranges
        var i: usize = 0;
        while (i < ranges.items.len) : (i += 1) {
            var j: usize = i + 1;
            while (j < ranges.items.len) : (j += 1) {
                // print("i:{d} j:{d}\n", .{ i, j });
                if (ranges.items[i].range_overlap(ranges.items[j])) {
                    ranges.items[i] = ranges.items[i].range_merge(ranges.items[j]);
                    _ = ranges.orderedRemove(j);
                    j = i; // ranges between i and j could now be overlapping with i so we must recheck them by reseting j index
                    continue;
                } else {
                    continue;
                }
            }
        }

        // create set of beacons
        var beacons = Map(Point, void).init(gpa);
        for (input) |pair| {
            const beacon = pair.snd;
            try beacons.put(beacon, {});
        }

        // for all the ranges, count the number of places that connot be a beacon
        var answer: isize = 0;
        for (ranges.items) |range| {
            const width = range.snd.x - range.fst.x + 1;
            // find number of beacons within the range
            var beacon_count: isize = 0;
            var beacon_it = beacons.keyIterator();
            while (beacon_it.next()) |beacon| {
                if (range.range_contains(beacon.*)) {
                    beacon_count += 1;
                }
            }
            answer += width - beacon_count;
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
