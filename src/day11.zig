const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day11.txt");
const example =
    \\Monkey 0:
    \\  Starting items: 79, 98
    \\  Operation: new = old * 19
    \\  Test: divisible by 23
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 3
    \\
    \\Monkey 1:
    \\  Starting items: 54, 65, 75, 74
    \\  Operation: new = old + 6
    \\  Test: divisible by 19
    \\    If true: throw to monkey 2
    \\    If false: throw to monkey 0
    \\
    \\Monkey 2:
    \\  Starting items: 79, 60, 97
    \\  Operation: new = old * old
    \\  Test: divisible by 13
    \\    If true: throw to monkey 1
    \\    If false: throw to monkey 3
    \\
    \\Monkey 3:
    \\  Starting items: 74
    \\  Operation: new = old + 3
    \\  Test: divisible by 17
    \\    If true: throw to monkey 0
    \\    If false: throw to monkey 1
;

const Monkey = struct {
    items: List(usize),
    operation: Operation,
    divisor: usize,
    if_true: usize,
    if_false: usize,
};
const Op = enum { add, mul };
const Operation = struct {
    op: Op,
    val: ?usize, // null means use old value
};

pub fn main() !void {
    const input: []Monkey = blk: {
        // var lines = tokenize(u8, example, "\r\n");
        var lines = tokenize(u8, data, "\r\n");
        var monkeys = List(Monkey).init(gpa);
        var monkey_index: usize = 0;
        while (lines.next()) |line_monkey_index| : (monkey_index += 1) {
            const line_items = lines.next().?;
            const line_operation = lines.next().?;
            const line_test = lines.next().?;
            const line_true = lines.next().?;
            const line_false = lines.next().?;

            const monkey_index_2: usize = blk2: {
                var iter = tokenize(u8, line_monkey_index, "Monkey :");
                const str = iter.next().?;
                const n = try parseInt(usize, str, 10);
                break :blk2 n;
            };
            assert(monkey_index == monkey_index_2);

            const items: List(usize) = blk2: {
                var list = List(usize).init(gpa);
                var iter = tokenize(u8, line_items, "Staring ems:,");
                while (iter.next()) |s| {
                    const n = try parseInt(usize, s, 10);
                    try list.append(n);
                }
                break :blk2 list;
            };

            const operation: Operation = blk2: {
                var iter = tokenize(u8, line_operation, " =");
                _ = iter.next();
                _ = iter.next();
                _ = iter.next();
                const op_str = iter.next().?;
                const val_str = iter.next().?;

                const op: Op = switch (op_str[0]) {
                    '*' => .mul,
                    '+' => .add,
                    else => unreachable,
                };

                const val: ?usize = switch (val_str[0]) {
                    'o' => null,
                    else => try parseInt(usize, val_str, 10),
                };

                break :blk2 Operation{ .op = op, .val = val };
            };

            const divisor: usize = blk2: {
                var iter = tokenize(u8, line_test, "Test: divbly");
                const n = try parseInt(usize, iter.next().?, 10);
                break :blk2 n;
            };

            const if_true: usize = blk2: {
                var iter = tokenize(u8, line_true, "If true:howmnky");
                const n = try parseInt(usize, iter.next().?, 10);
                break :blk2 n;
            };

            const if_false: usize = blk2: {
                var iter = tokenize(u8, line_false, "If false:throwmnky ");
                const n = try parseInt(usize, iter.next().?, 10);
                break :blk2 n;
            };

            const monkey = Monkey{
                .items = items,
                .operation = operation,
                .divisor = divisor,
                .if_true = if_true,
                .if_false = if_false,
            };

            try monkeys.append(monkey);
        }

        break :blk monkeys.toOwnedSlice();
    }; // end of parse input

    // print parsed input
    for (input) |monkey, index| {
        print("Monkey {d}\n", .{index});
        print("  Starting items: {d}\n", .{monkey.items.items});
        print("  {}\n", .{monkey.operation});
        print("  Test: divisible by {d}\n", .{monkey.divisor});
        print("    If true: throw to monkey {d}\n", .{monkey.if_true});
        print("    If true: throw to monkey {d}\n", .{monkey.if_false});
        print("\n", .{});
    }

    // part 1
    {
        // fill out state with input
        var monkeys: []Monkey = blk: {
            var list = List(Monkey).init(gpa);
            for (input) |old_monkey| {
                var new_monkey: Monkey = old_monkey;
                new_monkey.items = try List(usize).initCapacity(gpa, old_monkey.items.items.len);
                new_monkey.items.appendSliceAssumeCapacity(old_monkey.items.items);
                try list.append(new_monkey);

                // TODO: not sure why this doesn't work
                // var new_monkey: Monkey = old_monkey;
                // new_monkey.items = old_monkey.items.clone();
                // try list.append(new_monkey);
            }
            break :blk list.toOwnedSlice();
        };

        var round: usize = 0;
        while (round < 2) : (round += 1) {
            print("=== Round {d} ===\n", .{round});
            for (monkeys) |monkey, index| {
                var items = monkey.items;
                print("Monkey {d}\n", .{index});
                for (items.items) |item| {
                    print("  Monkey inspects an item with a worry level of {d}\n", .{item});
                }
                // TODO: this doesn't work because
                try items.resize(0);
            }
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
