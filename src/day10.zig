const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day10.txt");
const Operation = enum { noop, addx };
const Instruction = union(Operation) {
    noop: void,
    addx: isize,
};

pub fn main() !void {
    const input: []Instruction = blk: {
        var list = List(Instruction).init(gpa);
        var lines = tokenize(u8, data, "\r\n");
        while (lines.next()) |line| {
            switch (line[0]) {
                'n' => try list.append(Instruction{ .noop = .{} }),
                'a' => try list.append(Instruction{ .addx = try parseInt(isize, line[5..], 10) }),
                else => unreachable,
            }
        }
        break :blk list.toOwnedSlice();
    };

    var answer_1: isize = 0;
    var clk: isize = 0; // using 0-indexing instead of 1-indexing
    var x: isize = 1;
    var buffer = List(u8).init(gpa);
    for (input) |inst| {
        switch (inst) {
            .noop => {
                try display(clk, x, &buffer);
                answer_1 += signal_strenth(clk, x);
                clk += 1;

                continue;
            },
            .addx => |amount| {
                try display(clk, x, &buffer);
                answer_1 += signal_strenth(clk, x);
                clk += 1;

                try display(clk, x, &buffer);
                answer_1 += signal_strenth(clk, x);
                clk += 1;

                x += amount;
                continue;
            },
        }
    }

    const answer_2: []u8 = try detect_letters(gpa, buffer.items);

    print("{}\n", .{answer_1});
    //print("{s}\n", .{buffer.items});
    print("{s}\n", .{answer_2});

    assert(answer_1 == 12560);
    assert(std.mem.eql(u8, answer_2, "PLPAFBCL"));
}

fn display(clk: isize, x: isize, buffer: *List(u8)) !void {
    const pixel = @mod(clk, 40);
    const char: u8 = switch (x - pixel) {
        -1, 0, 1 => '#',
        else => ' ',
    };
    try buffer.append(char);
    if (pixel == 39) try buffer.append('\n');
}

fn signal_strenth(clk: isize, x: isize) isize {
    return if (@mod(clk, 40) == 19)
        (clk + 1) * x
    else
        0;
}

const alphabet = "ABCEFGHIJKLOPRSUYZ";

const alphabet_font = [_][]const u8{
    " ## \n#  #\n#  #\n####\n#  #\n#  #",
    "### \n#  #\n### \n#  #\n#  #\n### ",
    " ## \n#  #\n#   \n#   \n#  #\n ## ",
    "####\n#   \n### \n#   \n#   \n####",
    "####\n#   \n### \n#   \n#   \n#   ",
    " ## \n#  #\n#   \n# ##\n#  #\n ###",
    "#  #\n#  #\n####\n#  #\n#  #\n#  #",
    " ###\n  # \n  # \n  # \n  # \n ###",
    "  ##\n   #\n   #\n   #\n#  #\n ## ",
    "#  #\n# # \n##  \n# # \n# # \n#  #",
    "#   \n#   \n#   \n#   \n#   \n####",
    " ## \n#  #\n#  #\n#  #\n#  #\n ## ",
    "### \n#  #\n#  #\n### \n#   \n#   ",
    "### \n#  #\n#  #\n### \n# # \n#  #",
    " ###\n#   \n#   \n ## \n   #\n### ",
    "#  #\n#  #\n#  #\n#  #\n#  #\n ## ",
    "#   \n#   \n # #\n  # \n  # \n  # ",
    "####\n   #\n  # \n #  \n#   \n####",
};

fn detect_letters(allocator: std.mem.Allocator, buffer: []u8) ![]u8 {
    var output = List(u8).init(allocator);
    const display_width = std.mem.indexOf(u8, buffer, "\n").?;
    const letter_width = 5;
    const letter_height = 6;
    const num_letters = display_width / letter_width;

    var i: usize = 0;
    while (i < num_letters) : (i += 1) {
        const x: usize = i * letter_width;
        var y: usize = 0;
        var letter: [letter_height][]const u8 = undefined;
        var lines = tokenize(u8, buffer, "\n");
        while (lines.next()) |line| : (y += 1) {
            letter[y] = line[x .. x + letter_width - 1]; // don't include last column of letter
        }

        // print single letter to buffer
        var letter_print: [letter_height * letter_width]u8 = undefined;
        for (letter) |row_data, row| {
            for (row_data) |char, col| {
                const index = row * letter_width + col;
                letter_print[index] = char;
            }
            letter_print[(row + 1) * letter_width - 1] = '\n';
        }

        // compare printed letter to alphabet_font
        const character = for (alphabet_font) |letter_font, alphabet_index| {
            if (std.mem.eql(u8, letter_font, letter_print[0 .. letter_print.len - 1])) {
                break alphabet[alphabet_index];
            }
        } else '?';

        try output.append(character);
    }

    return output.toOwnedSlice();
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
