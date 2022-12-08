const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day07.txt");
const example =
    \\$ cd /
    \\$ ls
    \\dir a
    \\14848514 b.txt
    \\8504156 c.dat
    \\dir d
    \\$ cd a
    \\$ ls
    \\dir e
    \\29116 f
    \\2557 g
    \\62596 h.lst
    \\$ cd e
    \\$ ls
    \\584 i
    \\$ cd ..
    \\$ cd ..
    \\$ cd d
    \\$ ls
    \\4060174 j
    \\8033020 d.log
    \\5626152 d.ext
    \\7214296 k
;

const Id = u16;
const NodeType = enum { file, dir };
const Node = struct {
    const Self = @This();

    id: Id, // equal to the index into the node array
    type: NodeType,
    size: ?usize = null, // null indicates the directories size hasn't been determined as seen by the parent
    name: []const u8,
    parent: Id, // id of parent directory
    children: ?List(Id) = null, // list of nodes within a directory. Null if node is a file

    pub fn root(allocator: std.mem.Allocator) Self {
        return Self{
            .id = 0,
            .type = .dir,
            .size = 0,
            .name = "/",
            .parent = 0, // parent of root is itself
            .children = List(Id).init(allocator),
        };
    }

    // create file inside current directory
    pub fn new_file(self: *Self, id: Id, size: usize, name: []const u8) !Self {
        assert(self.type == .dir);

        // add node to children array in current directory
        try self.children.?.append(id);

        return Self{
            .id = id,
            .type = .file,
            .size = size,
            .name = name,
            .parent = self.id,
        };
    }

    // create empty directory inside current directory
    pub fn new_dir(self: *Self, allocator: std.mem.Allocator, id: Id, name: []const u8) !Self {
        assert(self.type == .dir);

        // add node to children array in current directory
        try self.children.?.append(id);

        return Self{
            .id = id,
            .type = .dir,
            .name = name,
            .parent = self.id,
            .children = List(Id).init(allocator),
        };
    }

    // returns id of child node if it exists. returns null if it does not.
    pub fn node_lookup(self: *Self, nodes: []Node, name: []const u8) ?Id {
        assert(self.type == .dir);
        return for (self.children.?.items) |child_id| {
            const child = nodes[child_id];
            if (std.mem.eql(u8, child.name, name)) {
                break child_id;
            }
        } else null;
    }
};

const CommandType = enum { cd, ls };
const Command = union(CommandType) {
    cd: []const u8, // directory to navigate to
    ls: void,
};

pub fn main() !void {
    var nodes = List(Node).init(gpa);

    // create root
    try nodes.append(Node.root(gpa));
    const root: Id = 0;

    // var commands_iter = tokenize(u8, example, "$");
    var commands_iter = tokenize(u8, data, "$");

    // create tree of nodes
    {
        var cwd: Id = root;
        while (commands_iter.next()) |command_and_output| {
            var lines_iter = tokenize(u8, command_and_output, "\r\n");

            // parse command
            const command: Command = command_blk: {
                const command_str_full = lines_iter.next().?;
                var command_parts = tokenize(u8, command_str_full, " ");
                const str = command_parts.next().?;
                const ret = if (std.mem.eql(u8, str, "cd"))
                    Command{ .cd = command_parts.next().? }
                else if (std.mem.eql(u8, str, "ls"))
                    Command{ .ls = {} }
                else
                    unreachable;

                break :command_blk ret;
            };

            // operate on command
            switch (command) {
                .cd => |dir_name| {
                    // print("cd {s}\n", .{dir_name});
                    if (std.mem.eql(u8, dir_name, "/")) {
                        // go to root
                        const dir_id = root;

                        assert(dir_id == nodes.items[dir_id].id);
                        cwd = dir_id;
                    } else if (std.mem.eql(u8, dir_name, "..")) {
                        // go to parent
                        const dir_id = nodes.items[cwd].parent;

                        assert(dir_id == nodes.items[dir_id].id);
                        cwd = dir_id;
                    } else if (nodes.items[cwd].node_lookup(nodes.items, dir_name)) |dir_id| {
                        // direcotry exists

                        assert(dir_id == nodes.items[dir_id].id);
                        cwd = dir_id;
                    } else {
                        // create directory
                        const dir_id = @intCast(Id, nodes.items.len);
                        var new_node = try nodes.items[cwd].new_dir(gpa, dir_id, dir_name);
                        try nodes.append(new_node);

                        assert(dir_id == nodes.items[dir_id].id);
                        cwd = dir_id;
                        unreachable; // we never enter a directory before it gets listed with `ls`
                    }
                },
                .ls => {
                    // parse command output
                    while (lines_iter.next()) |line| {
                        var parts = tokenize(u8, line, " ");
                        const fst = parts.next().?; // either "dir" or a size
                        const name = parts.next().?; // name of node

                        if (std.mem.eql(u8, fst, "dir")) {
                            if (nodes.items[cwd].node_lookup(nodes.items, name)) |_| {
                                // dir already exists
                                unreachable; // a directory never gets listed twice
                            } else {
                                const dir_id = @intCast(Id, nodes.items.len);
                                var new_node = try nodes.items[cwd].new_dir(gpa, dir_id, name);
                                try nodes.append(new_node);
                            }
                        } else {
                            const size = try parseInt(usize, fst, 10);
                            if (nodes.items[cwd].node_lookup(nodes.items, name)) |_| {
                                // dir already exists
                                unreachable; // a file never gets listed twice
                            } else {
                                const dir_id = @intCast(Id, nodes.items.len);
                                var new_node = try nodes.items[cwd].new_file(dir_id, size, name);
                                try nodes.append(new_node);
                            }
                        }
                    }
                },
            }
        }
    }

    // depth-first search through tree of nodes to fill in sizes
    {
        const IdPair = struct {
            cwd_id: Id,
            child_index: usize,
        };
        var id_stack = List(IdPair).init(gpa);
        try id_stack.append(IdPair{ .cwd_id = root, .child_index = 0 });
        while (id_stack.items.len > 0) {
            const id_pair = id_stack.pop();
            const cwd_id = id_pair.cwd_id;
            var cwd = &nodes.items[cwd_id];
            var child_index = id_pair.child_index;
            for (cwd.children.?.items[child_index..]) |child_id| {
                var child = &nodes.items[child_id];
                switch (child.type) {
                    .dir => {
                        if (child.size) |*child_size| {
                            if (cwd.size) |*size| {
                                size.* += child_size.*;
                            } else {
                                std.debug.panic("BAD", .{});
                            }
                        } else {
                            // enter directory
                            child.size = 0;
                            try id_stack.append(IdPair{ .cwd_id = cwd_id, .child_index = child_index });
                            try id_stack.append(IdPair{ .cwd_id = child_id, .child_index = 0 });
                            break;
                        }
                    },
                    .file => {
                        // add file to size of directory
                        if (cwd.size) |*size| {
                            size.* += child.size.?;
                        } else {
                            unreachable;
                        }
                    },
                }
                child_index += 1;
            }
        }
    }

    // find sum of directory sizes
    var answer_1: usize = 0;
    for (nodes.items) |node| {
        switch (node.type) {
            .dir => {
                if (node.size.? <= 100_000) {
                    answer_1 += node.size.?;
                }
            },
            .file => {},
        }
    }

    // find smallest directory such that it would bring the size of root down to 40,000,000
    const root_size: usize = nodes.items[root].size.?;
    const min_size: usize = root_size - 40_000_000; // minimum size of the directory we need to delete
    var answer_2: usize = std.math.maxInt(usize);
    for (nodes.items) |node| {
        switch (node.type) {
            .dir => {
                if (node.size.? >= min_size) {
                    answer_2 = min(answer_2, node.size.?);
                }
            },
            .file => {},
        }
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
