const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day08.txt");
const example =
    \\30373
    \\25512
    \\65332
    \\33549
    \\35390
;

pub fn main() !void {
    const input: [][]const u8 = blk: {
        var iter = tokenize(u8, data, "\r\n");
        // var iter = tokenize(u8, example, "\r\n");
        var rows = List([]const u8).init(gpa);
        while (iter.next()) |line| {
            try rows.append(line);
        }
        break :blk rows.toOwnedSlice();
    };

    const height = input.len;
    const width = input[0].len;

    // part 1
    {
        // intitialize output matrix of false bools
        var output: [][]bool = blk: {
            var rows = try gpa.alloc([]bool, height);
            for (rows) |*row| {
                row.* = try gpa.alloc(bool, width);
                for (row.*) |*cell| {
                    cell.* = false;
                }
            }
            break :blk rows;
        };

        // iterate rows forwards
        {
            var i: usize = 0;
            while (i < height) : (i += 1) {
                var tallest: u8 = '0' - 1;
                var j: usize = 0;
                while (j < width) : (j += 1) {
                    const tree = input[i][j];
                    const visible: bool = tallest < tree;
                    output[i][j] = output[i][j] or visible;
                    tallest = max(tallest, tree);
                }
            }
        }

        // iterate rows backwards
        {
            var i: usize = 0;
            while (i < height) : (i += 1) {
                var tallest: u8 = '0' - 1;
                var j1: usize = width;
                while (j1 > 0) : (j1 -= 1) {
                    const j = j1 - 1;

                    const tree = input[i][j];
                    const visible: bool = tallest < tree;
                    output[i][j] = output[i][j] or visible;
                    tallest = max(tallest, tree);
                }
            }
        }

        // iterate columns forwards
        {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                var tallest: u8 = '0' - 1;
                var i: usize = 0;
                while (i < height) : (i += 1) {
                    const tree = input[i][j];
                    const visible: bool = tallest < tree;
                    output[i][j] = output[i][j] or visible;
                    tallest = max(tallest, tree);
                }
            }
        }

        // iterate columns backwards
        {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                var tallest: u8 = '0' - 1;
                var i_1: usize = height;
                while (i_1 > 0) : (i_1 -= 1) {
                    const i = i_1 - 1;

                    const tree = input[i][j];
                    const visible: bool = tallest < tree;
                    output[i][j] = output[i][j] or visible;
                    tallest = max(tallest, tree);
                }
            }
        }

        // count visible trees
        var answer_1: usize = 0;
        for (output) |row| {
            for (row) |cell| {
                if (cell) answer_1 += 1;
            }
        }

        print("{d}\n", .{answer_1});
    }

    // part 2
    {
        // each directional matrix represents the number of trees visible when looking in that direction
        // zero out each directional matrix
        const Dist = usize;
        var left: [][]Dist = blk: {
            var rows = try gpa.alloc([]Dist, height);
            for (rows) |*row| {
                row.* = try gpa.alloc(Dist, width);
                for (row.*) |*cell| {
                    cell.* = 0;
                }
            }
            break :blk rows;
        };
        var right: [][]Dist = blk: {
            var rows = try gpa.alloc([]Dist, height);
            for (rows) |*row| {
                row.* = try gpa.alloc(Dist, width);
                for (row.*) |*cell| {
                    cell.* = 0;
                }
            }
            break :blk rows;
        };
        var up: [][]Dist = blk: {
            var rows = try gpa.alloc([]Dist, height);
            for (rows) |*row| {
                row.* = try gpa.alloc(Dist, width);
                for (row.*) |*cell| {
                    cell.* = 0;
                }
            }
            break :blk rows;
        };
        var down: [][]Dist = blk: {
            var rows = try gpa.alloc([]Dist, height);
            for (rows) |*row| {
                row.* = try gpa.alloc(Dist, width);
                for (row.*) |*cell| {
                    cell.* = 0;
                }
            }
            break :blk rows;
        };

        // In each direction, for each potential treehouse, find the distance to the closest tree which is >= the treehouse
        // Do this by tracking the location of the last seen tree for each possible height
        // iterate rows forwards (from left)
        {
            var i: usize = 0;
            while (i < height) : (i += 1) {
                var locations: [10]usize = undefined;
                for (locations) |*val| val.* = 0;
                var index: usize = 0;
                var j: usize = 0;
                while (j < width) : ({
                    j += 1;
                    index += 1;
                }) {
                    const tree = input[i][j] - '0';
                    var smallest_distance: Dist = std.math.maxInt(Dist);
                    for (locations[tree..locations.len]) |location| {
                        const distance = index - location;
                        smallest_distance = min(distance, smallest_distance);
                    }
                    left[i][j] = smallest_distance;
                    locations[tree] = index;
                }
            }
        }

        // // iterate rows backwards
        {
            var i: usize = 0;
            while (i < height) : (i += 1) {
                var locations: [10]usize = undefined;
                for (locations) |*val| val.* = 0;
                var index: usize = 0;
                var j_1: usize = width;
                while (j_1 > 0) : ({
                    j_1 -= 1;
                    index += 1;
                }) {
                    const j = j_1 - 1;

                    const tree = input[i][j] - '0';
                    var smallest_distance: Dist = std.math.maxInt(Dist);
                    for (locations[tree..locations.len]) |location| {
                        const distance = index - location;
                        smallest_distance = min(distance, smallest_distance);
                    }
                    right[i][j] = smallest_distance;
                    locations[tree] = index;
                }
            }
        }

        // // iterate columns forwards
        {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                var locations: [10]usize = undefined;
                for (locations) |*val| val.* = 0;
                var index: usize = 0;
                var i: usize = 0;
                while (i < height) : ({
                    i += 1;
                    index += 1;
                }) {
                    const tree = input[i][j] - '0';
                    var smallest_distance: Dist = std.math.maxInt(Dist);
                    for (locations[tree..locations.len]) |location| {
                        const distance = index - location;
                        smallest_distance = min(distance, smallest_distance);
                    }
                    up[i][j] = smallest_distance;
                    locations[tree] = index;
                }
            }
        }

        // // iterate columns backwards
        {
            var j: usize = 0;
            while (j < width) : (j += 1) {
                var locations: [10]usize = undefined;
                for (locations) |*val| val.* = 0;
                var index: usize = 0;
                var i_1: usize = height;
                while (i_1 > 0) : ({
                    i_1 -= 1;
                    index += 1;
                }) {
                    const i = i_1 - 1;

                    const tree = input[i][j] - '0';
                    var smallest_distance: Dist = std.math.maxInt(Dist);
                    for (locations[tree..locations.len]) |location| {
                        const distance = index - location;
                        smallest_distance = min(distance, smallest_distance);
                    }
                    down[i][j] = smallest_distance;
                    locations[tree] = index;
                }
            }
        }

        // find maximum visibility score
        var answer_2: usize = 0;
        for (up) |row, i| {
            for (row) |_, j| {
                const score: usize = left[i][j] * right[i][j] * up[i][j] * down[i][j];
                answer_2 = max(answer_2, score);
            }
        }

        print("{d}\n", .{answer_2});
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
