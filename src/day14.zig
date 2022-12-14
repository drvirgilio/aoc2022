const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day14.txt");
const example =
    \\498,4 -> 498,6 -> 496,6
    \\503,4 -> 502,4 -> 502,9 -> 494,9
;

const Point = struct {
    const Self = @This();
    x: u16,
    y: u16,
    pub fn down_left(self: Self) Self {
        return Self{ .x = self.x - 1, .y = self.y + 1 };
    }
    pub fn down(self: Self) Self {
        return Self{ .x = self.x, .y = self.y + 1 };
    }
    pub fn down_right(self: Self) Self {
        return Self{ .x = self.x + 1, .y = self.y + 1 };
    }
};
const Edge = struct { fst: Point, snd: Point };

pub fn main() !void {
    // parse input to get edges
    const edges: []const Edge = blk: {
        var edges_ = List(Edge).init(gpa);
        // var lines_it = tokenize(u8, example, "\r\n");
        var lines_it = tokenize(u8, data, "\r\n");
        while (lines_it.next()) |line_s| {
            var points_it = tokenize(u8, line_s, " ->");
            var prev: ?Point = null;
            while (points_it.next()) |point_s| {
                var values_it = tokenize(u8, point_s, ",");
                const x: u16 = try parseInt(u16, values_it.next().?, 10);
                const y: u16 = try parseInt(u16, values_it.next().?, 10);
                const this: Point = Point{ .x = x, .y = y };
                if (prev) |prev_| {
                    // create edge
                    const edge = Edge{ .fst = prev_, .snd = this };
                    try edges_.append(edge);
                }
                prev = this;
            }
        }
        break :blk edges_.toOwnedSlice();
    };
    defer gpa.free(edges);

    // create set of points which represent the walls\
    var walls: Map(Point, void) = blk: {
        var walls_ = Map(Point, void).init(gpa);
        for (edges) |edge| {
            if (edge.fst.x == edge.snd.x) {
                // vertical wall
                const x = edge.fst.x;
                const fst_above_snd: bool = edge.fst.y < edge.snd.y;
                const start = if (fst_above_snd) edge.fst.y else edge.snd.y;
                const end = if (!fst_above_snd) edge.fst.y else edge.snd.y;
                var y: u16 = start;
                while (y <= end) : (y += 1) {
                    const point = Point{ .x = x, .y = y };
                    try walls_.put(point, {});
                }
            } else if (edge.fst.y == edge.snd.y) {
                // horizontal wall
                const y = edge.fst.y;
                const fst_leftof_snd: bool = edge.fst.x < edge.snd.x;
                const start = if (fst_leftof_snd) edge.fst.x else edge.snd.x;
                const end = if (!fst_leftof_snd) edge.fst.x else edge.snd.x;
                var x: u16 = start;
                while (x <= end) : (x += 1) {
                    const point = Point{ .x = x, .y = y };
                    try walls_.put(point, {});
                }
            } else unreachable; // no diagonal edges allowed
        }
        break :blk walls_;
    };
    defer walls.deinit();

    // calculate lower boundary of system
    // any sand which goes to the left (<fst.x), right (>snd.x), or below (>y) this line segment is gone forever
    const boundary: Edge = blk: {
        var max_x: u16 = 0;
        var max_y: u16 = 0;
        var min_x: u16 = std.math.maxInt(u16);

        var walls_it = walls.keyIterator();
        while (walls_it.next()) |point| {
            max_x = max(point.x, max_x);
            max_y = max(point.y, max_y);
            min_x = min(point.x, min_x);
        }

        const fst = Point{ .x = min_x, .y = max_y };
        const snd = Point{ .x = max_x, .y = max_y };

        break :blk Edge{ .fst = fst, .snd = snd };
    };

    // part 1
    {
        // game state
        var sand = Map(Point, void).init(gpa);

        // simulate all sand
        var round: usize = 0;
        outer: while (round < 1000) : (round += 1) {
            // simulate sand unit
            var this: Point = Point{ .x = 500, .y = 0 };
            var prev_: ?Point = null;
            inner: while (true) {
                // print("{}\n", .{this});
                const outside_box: bool = (this.y > boundary.fst.y) or (this.x < boundary.fst.x) or (this.x > boundary.snd.x);
                const not_moving: bool = if (prev_) |prev| (this.x == prev.x) and (this.y == prev.y) else false;
                if (outside_box or not_moving) {
                    // add this location to sand map
                    try sand.put(this, {});
                    if (outside_box) {
                        print("{d}\n", .{round});
                        break :outer;
                    } else {
                        break :inner;
                    }
                }

                // move this unit of sand
                prev_ = this;
                if (!sand.contains(this.down()) and !walls.contains(this.down())) {
                    // move sand down
                    this.y += 1;
                } else if (!sand.contains(this.down_left()) and !walls.contains(this.down_left())) {
                    // move sand down-left
                    this.y += 1;
                    this.x -= 1;
                } else if (!sand.contains(this.down_right()) and !walls.contains(this.down_right())) {
                    // move sand down-right
                    this.y += 1;
                    this.x += 1;
                }
            }

            // print board
            // {
            //     var y: u16 = 0;
            //     while (y <= boundary.fst.y) : (y += 1) {
            //         var x: u16 = boundary.fst.x;
            //         while (x <= boundary.snd.x) : (x += 1) {
            //             const spot = Point{ .x = x, .y = y };
            //             if (walls.get(spot)) |_| {
            //                 print("#", .{});
            //             } else if (spot.x == 500 and spot.y == 0) {
            //                 print("+", .{});
            //             } else if (sand.contains(spot)) {
            //                 print("o", .{});
            //             } else {
            //                 print(".", .{});
            //             }
            //         }
            //         print("\n", .{});
            //     }
            //     print("\n", .{});
            // }
        }
    }

    // part 2
    {
        // game state
        var sand = Map(Point, void).init(gpa);

        // simulate all sand
        var round: usize = 0;
        outer: while (round < 10_000_000) : (round += 1) {
            // simulate sand unit
            var this: Point = Point{ .x = 500, .y = 0 };
            var prev_: ?Point = null;
            inner: while (true) {
                // print("{}\n", .{this});
                const not_moving: bool = if (prev_) |prev| (this.x == prev.x) and (this.y == prev.y) else false;
                if (not_moving) {
                    // add this location to sand map
                    try sand.put(this, {});
                    if (this.y == 0 and this.x == 500) {
                        print("{d}\n", .{round + 1});
                        break :outer;
                    } else {
                        break :inner;
                    }
                }

                // move this unit of sand
                prev_ = this;
                if (!sand.contains(this.down()) and !walls.contains(this.down()) and (this.y < boundary.fst.y + 1)) {
                    // move sand down
                    this.y += 1;
                } else if (!sand.contains(this.down_left()) and !walls.contains(this.down_left()) and (this.y < boundary.fst.y + 1)) {
                    // move sand down-left
                    this.y += 1;
                    this.x -= 1;
                } else if (!sand.contains(this.down_right()) and !walls.contains(this.down_right()) and (this.y < boundary.fst.y + 1)) {
                    // move sand down-right
                    this.y += 1;
                    this.x += 1;
                }
            }

            // print board
            // {
            //     var y: u16 = 0;
            //     while (y <= boundary.fst.y + 2) : (y += 1) {
            //         var x: u16 = boundary.fst.x;
            //         while (x <= boundary.snd.x) : (x += 1) {
            //             const spot = Point{ .x = x, .y = y };
            //             if (walls.get(spot)) |_| {
            //                 print("#", .{});
            //             } else if (spot.x == 500 and spot.y == 0) {
            //                 print("+", .{});
            //             } else if (sand.contains(spot)) {
            //                 print("o", .{});
            //             } else {
            //                 print(".", .{});
            //             }
            //         }
            //         print("\n", .{});
            //     }
            //     print("\n", .{});
            // }
        }
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
