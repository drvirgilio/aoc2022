const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day09.txt");
const example =
    \\R 4
    \\U 4
    \\L 3
    \\D 1
    \\R 4
    \\D 1
    \\L 5
    \\R 2
;

const Direction = enum { L, R, U, D };
const Command = struct {
    direction: Direction,
    distance: u8,
};
const Position = struct { x: isize, y: isize };

pub fn main() !void {
    const input = blk: {
        var list = List(Command).init(gpa);
        var lines = tokenize(u8, data, "\r\n");
        //var lines = tokenize(u8, example, "\r\n");
        while (lines.next()) |line| {
            var parts = tokenize(u8, line, " ");
            const direction: Direction = switch (parts.next().?[0]) {
                'L' => .L,
                'R' => .R,
                'U' => .U,
                'D' => .D,
                else => unreachable,
            };
            const distance = try parseInt(u8, parts.next().?, 10);
            try list.append(Command{
                .direction = direction,
                .distance = distance,
            });
        }
        break :blk list.toOwnedSlice();
    };

    // part 1
    {
        var visits = Map(Position, usize).init(gpa); // count number of times we visit each location
        defer visits.deinit();

        var head = Position{ .x = 0, .y = 0 };
        var tail = Position{ .x = 0, .y = 0 };

        // put start into visits map
        try visits.put(tail, 1);

        //printBoard(head, tail);

        for (input) |cmd| {
            //printCommand(cmd);
            {
                var distance = cmd.distance;
                while (distance > 0) : (distance -= 1) {
                    switch (cmd.direction) {
                        .L => head.x -= 1,
                        .R => head.x += 1,
                        .U => head.y += 1,
                        .D => head.y -= 1,
                    }

                    const dx = head.x - tail.x;
                    const dy = head.y - tail.y;

                    if (dx > 1) {
                        tail.x = head.x - 1;
                        tail.y = head.y;
                    }
                    if (dx < -1) {
                        tail.x = head.x + 1;
                        tail.y = head.y;
                    }
                    if (dy > 1) {
                        tail.x = head.x;
                        tail.y = head.y - 1;
                    }
                    if (dy < -1) {
                        tail.x = head.x;
                        tail.y = head.y + 1;
                    }

                    // add visit to visits map
                    if (visits.get(tail)) |num_visits| {
                        try visits.put(tail, num_visits + 1);
                    } else {
                        try visits.put(tail, 1);
                    }

                    //printBoard(head, tail);
                }
            }
        }

        // count visits
        const answer_1: usize = visits.count();
        //printBoardVisits(visits);
        print("{d}\n", .{answer_1});
    }
}

fn printCommand(command: Command) void {
    const c: u8 = switch (command.direction) {
        .L => 'L',
        .R => 'R',
        .U => 'U',
        .D => 'D',
    };

    print("== {c} {d} ==\n\n", .{ c, command.distance });
}

fn printBoard(head: Position, tail: Position) void {
    const height = 5;
    const width = 6;

    var i: usize = height;
    while (i > 0) : (i -= 1) {
        const y = i - 1;
        var j: usize = 0;
        while (j < width) : (j += 1) {
            const x = j;
            if (head.x == x and head.y == y)
                print("H", .{})
            else if (tail.x == x and tail.y == y)
                print("T", .{})
            else if (x == 0 and y == 0)
                print("s", .{})
            else
                print(".", .{});
        }
        print("\n", .{});
    }
    print("\n", .{});
}

fn printBoardVisits(visits: Map(Position, usize)) void {
    const height = 5;
    const width = 6;

    var i: isize = height;
    while (i > 0) : (i -= 1) {
        const y = i - 1;
        var j: isize = 0;
        while (j < width) : (j += 1) {
            const x = j;
            const pos = Position{ .x = x, .y = y };
            if (visits.get(pos)) |num_visits| {
                assert(num_visits > 0);
                print("#", .{});
            } else {
                print(".", .{});
            }
        }
        print("\n", .{});
    }
    print("\n", .{});
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
