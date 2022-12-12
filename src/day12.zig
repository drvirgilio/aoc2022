const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day12.txt");
const example =
    \\Sabqponm
    \\abcryxxl
    \\accszExk
    \\acctuvwj
    \\abdefghi
;

const Location = struct {
    const Self = @This();

    row: usize,
    col: usize,

    pub fn north(self: Self) Self {
        return Self{ .row = self.row - 1, .col = self.col };
    }
    pub fn south(self: Self) Self {
        return Self{ .row = self.row + 1, .col = self.col };
    }
    pub fn west(self: Self) Self {
        return Self{ .row = self.row, .col = self.col - 1 };
    }
    pub fn east(self: Self) Self {
        return Self{ .row = self.row, .col = self.col + 1 };
    }

    /// taxicab distance between two locations
    pub fn distance(self: Self, other: Location) usize {
        const d_row = if (self.row > other.row) self.row - other.row else other.row - self.row;
        const d_col = if (self.col > other.col) self.col - other.col else other.col - self.col;
        return (d_row + d_col);
    }

    pub fn eql(self: Self, other: Location) bool {
        return (self.row == other.row and self.col == other.col);
    }
};

const Input = struct {
    start: Location,
    end: Location,
    matrix: [][]u8,
};
// represents if walking a certain direction is possible
const IsPossible = struct {
    north: bool,
    south: bool,
    west: bool,
    east: bool,
};

pub fn main() !void {
    const input: Input = blk: {
        var matrix = List([]u8).init(gpa);
        var start: Location = undefined;
        var end: Location = undefined;
        var lines = tokenize(u8, data, "\r\n");
        // var lines = tokenize(u8, example, "\r\n");
        var row: usize = 0;
        while (lines.next()) |line| : (row += 1) {
            var list = List(u8).init(gpa);
            for (line) |char, col| {
                const value = switch (char) {
                    'a'...'z' => char,
                    'S' => blk_S: {
                        start = .{ .row = row, .col = col };
                        break :blk_S 'a';
                    },
                    'E' => blk_E: {
                        end = .{ .row = row, .col = col };
                        break :blk_E 'z';
                    },
                    else => unreachable,
                };
                try list.append(value);
            }
            try matrix.append(list.toOwnedSlice());
        }
        break :blk .{
            .start = start,
            .end = end,
            .matrix = matrix.toOwnedSlice(),
        };
    };

    // for (input.matrix) |str| {
    //     print("{s}\n", .{str});
    // }

    // part 1
    {
        const height = input.matrix.len;
        const width = input.matrix[0].len;

        var graph = Map(Location, IsPossible).init(gpa);
        for (input.matrix) |str, row| {
            for (str) |val, col| {
                const location = Location{ .row = row, .col = col };
                var is_possible: IsPossible = undefined;

                // north
                is_possible.north = if (row > 0)
                    if (input.matrix[row - 1][col] <= val + 1) true else false
                else
                    false;

                // south
                is_possible.south = if (row + 1 < height)
                    if (input.matrix[row + 1][col] <= val + 1) true else false
                else
                    false;

                // west
                is_possible.west = if (col > 0)
                    if (input.matrix[row][col - 1] <= val + 1) true else false
                else
                    false;

                // east
                is_possible.east = if (col + 1 < width)
                    if (input.matrix[row][col + 1] <= val + 1) true else false
                else
                    false;

                try graph.put(location, is_possible);
            }
        }

        // // print graph
        // for (input.matrix) |str, row| {
        //     for (str) |char, col| {
        //         // print location value
        //         print("{c}", .{char});

        //         // print east-west connections
        //         if (col + 1 < width) {
        //             const location = Location{ .row = row, .col = col };
        //             const east = Location{ .row = row, .col = col + 1 };

        //             const pos_this = graph.get(location).?;
        //             const pos_east = graph.get(east).?;

        //             if (pos_this.east and pos_east.west)
        //                 print("-", .{})
        //             else if (pos_this.east)
        //                 print(">", .{})
        //             else if (pos_east.west)
        //                 print("<", .{})
        //             else
        //                 print(" ", .{});
        //         }
        //     }
        //     print("\n", .{});

        //     // print north-south connections
        //     if (row + 1 < height) {
        //         for (str) |_, col| {
        //             const location = Location{ .row = row, .col = col };
        //             const south = Location{ .row = row + 1, .col = col };

        //             const pos_this = graph.get(location).?;
        //             const pos_south = graph.get(south).?;

        //             if (pos_this.south and pos_south.north)
        //                 print("| ", .{})
        //             else if (pos_this.south)
        //                 print("v ", .{})
        //             else if (pos_south.north)
        //                 print("^ ", .{})
        //             else
        //                 print("  ", .{});
        //         }
        //         print("\n", .{});
        //     }
        // }

        // set of unvisited nodes
        var unvisited = Map(Location, void).init(gpa);
        for (input.matrix) |str, row| {
            for (str) |_, col| {
                try unvisited.put(Location{ .row = row, .col = col }, .{});
            }
        }

        // tenative distance value for each node
        var tentative_distance = Map(Location, usize).init(gpa);
        for (input.matrix) |str, row| {
            for (str) |_, col| {
                const dist: usize = if (input.start.row == row and input.start.col == col) 0 else std.math.maxInt(usize);
                try tentative_distance.put(Location{ .row = row, .col = col }, dist);
            }
        }

        var this = input.start;
        while (true) {
            var neighbors = try List(Location).initCapacity(gpa, 4);
            defer neighbors.deinit();
            if (graph.get(this).?.north) try neighbors.append(this.north());
            if (graph.get(this).?.south) try neighbors.append(this.south());
            if (graph.get(this).?.east) try neighbors.append(this.east());
            if (graph.get(this).?.west) try neighbors.append(this.west());

            for (neighbors.items) |neighbor| {
                if (unvisited.get(neighbor)) |_| {
                    const old_dist = tentative_distance.get(neighbor).?;
                    const new_dist = tentative_distance.get(this).? + 1;
                    try tentative_distance.put(neighbor, min(old_dist, new_dist));
                }
            }

            //print("visited {}\n", .{this});
            if (unvisited.remove(this)) {} else unreachable;

            if (unvisited.get(input.end)) |_| {} else {
                const total_dist = tentative_distance.get(input.end).?;
                print("{d}\n", .{total_dist});
                break;
            }

            // find node with minimum tentative distance and set current_node to that
            var min_dist: usize = std.math.maxInt(usize);
            // var min_dist_node: Location = undefined;
            var unvisited_iter = unvisited.keyIterator();
            while (unvisited_iter.next()) |location| {
                const dist = tentative_distance.get(location.*).?;
                if (dist <= min_dist) {
                    min_dist = dist;
                    this = location.*;
                }
            }
        }
    }

    // part 2
    var puzzle_min_dist: usize = std.math.maxInt(usize);
    for (input.matrix) |str_, row_| {
        for (str_) |val_, col_| {
            if (val_ != 'a') continue;
            const start = Location{ .row = row_, .col = col_ };
            // print("{}\n", .{start});

            const height = input.matrix.len;
            const width = input.matrix[0].len;

            var graph = Map(Location, IsPossible).init(gpa);
            defer graph.deinit();
            for (input.matrix) |str, row| {
                for (str) |val, col| {
                    const location = Location{ .row = row, .col = col };
                    var is_possible: IsPossible = undefined;

                    // north
                    is_possible.north = if (row > 0)
                        if (input.matrix[row - 1][col] <= val + 1) true else false
                    else
                        false;

                    // south
                    is_possible.south = if (row + 1 < height)
                        if (input.matrix[row + 1][col] <= val + 1) true else false
                    else
                        false;

                    // west
                    is_possible.west = if (col > 0)
                        if (input.matrix[row][col - 1] <= val + 1) true else false
                    else
                        false;

                    // east
                    is_possible.east = if (col + 1 < width)
                        if (input.matrix[row][col + 1] <= val + 1) true else false
                    else
                        false;

                    try graph.put(location, is_possible);
                }
            }

            // // print graph
            // for (input.matrix) |str, row| {
            //     for (str) |char, col| {
            //         // print location value
            //         print("{c}", .{char});

            //         // print east-west connections
            //         if (col + 1 < width) {
            //             const location = Location{ .row = row, .col = col };
            //             const east = Location{ .row = row, .col = col + 1 };

            //             const pos_this = graph.get(location).?;
            //             const pos_east = graph.get(east).?;

            //             if (pos_this.east and pos_east.west)
            //                 print("-", .{})
            //             else if (pos_this.east)
            //                 print(">", .{})
            //             else if (pos_east.west)
            //                 print("<", .{})
            //             else
            //                 print(" ", .{});
            //         }
            //     }
            //     print("\n", .{});

            //     // print north-south connections
            //     if (row + 1 < height) {
            //         for (str) |_, col| {
            //             const location = Location{ .row = row, .col = col };
            //             const south = Location{ .row = row + 1, .col = col };

            //             const pos_this = graph.get(location).?;
            //             const pos_south = graph.get(south).?;

            //             if (pos_this.south and pos_south.north)
            //                 print("| ", .{})
            //             else if (pos_this.south)
            //                 print("v ", .{})
            //             else if (pos_south.north)
            //                 print("^ ", .{})
            //             else
            //                 print("  ", .{});
            //         }
            //         print("\n", .{});
            //     }
            // }

            // set of unvisited nodes
            var unvisited = Map(Location, void).init(gpa);
            defer unvisited.deinit();
            for (input.matrix) |str, row| {
                for (str) |_, col| {
                    try unvisited.put(Location{ .row = row, .col = col }, .{});
                }
            }

            // tenative distance value for each node
            var tentative_distance = Map(Location, usize).init(gpa);
            defer tentative_distance.deinit();
            for (input.matrix) |str, row| {
                for (str) |_, col| {
                    const dist: usize = if (start.row == row and start.col == col) 0 else std.math.maxInt(usize);
                    try tentative_distance.put(Location{ .row = row, .col = col }, dist);
                }
            }

            var this = start;
            while (true) {
                var neighbors = try List(Location).initCapacity(gpa, 4);
                defer neighbors.deinit();
                if (graph.get(this).?.north) try neighbors.append(this.north());
                if (graph.get(this).?.south) try neighbors.append(this.south());
                if (graph.get(this).?.east) try neighbors.append(this.east());
                if (graph.get(this).?.west) try neighbors.append(this.west());

                for (neighbors.items) |neighbor| {
                    if (unvisited.get(neighbor)) |_| {
                        const old_dist = tentative_distance.get(neighbor).?;
                        const new_dist = tentative_distance.get(this).? + 1;
                        try tentative_distance.put(neighbor, min(old_dist, new_dist));
                    }
                }

                //print("visited {}\n", .{this});
                if (unvisited.remove(this)) {} else unreachable;

                // stop if there exists no path to the end
                var unvisited_iter2 = unvisited.keyIterator();
                const no_path: bool = while (unvisited_iter2.next()) |loc| {
                    const dist = tentative_distance.get(loc.*).?;
                    if (dist < std.math.maxInt(usize)) break false;
                } else true;
                if (no_path) break;

                // stop if end is visited
                if (unvisited.get(input.end)) |_| {} else {
                    const total_dist = tentative_distance.get(input.end).?;
                    if (total_dist <= puzzle_min_dist) {
                        puzzle_min_dist = total_dist;
                        // print("{}\n", .{puzzle_min_dist});
                    }
                    break;
                }

                // find node with minimum tentative distance and set current_node to that
                var min_dist: usize = std.math.maxInt(usize);
                // var min_dist_node: Location = undefined;
                var unvisited_iter = unvisited.keyIterator();
                while (unvisited_iter.next()) |location| {
                    const dist = tentative_distance.get(location.*).?;
                    if (dist <= min_dist) {
                        min_dist = dist;
                        this = location.*;
                    }
                }
                if (min_dist >= puzzle_min_dist) break;
            }
        }
    }

    print("{d}\n", .{puzzle_min_dist});
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
