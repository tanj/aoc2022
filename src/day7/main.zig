const std = @import("std");
const mecha = @import("mecha");

const mem = std.mem;

const Command = enum {
    cd,
    ls,
};

const prompt = mecha.string("$ ").discard();
const cmd = mecha.enumeration(Command);
const arg = mecha.rest.asStr();

const Statement = struct {
    cmd: Command,
    arg: []const u8,
};

const statement = mecha.combine(.{ prompt, cmd, mecha.opt(ws).discard(), arg }).map(mecha.toStruct(Statement));

const ListingTypeTag = enum {
    dir,
    size,
};

const ListingType = union(ListingTypeTag) {
    dir: std.StringHashMap(Listing),
    size: usize,
};

const Listing = struct {
    lt: ListingType,
    name: []const u8,
    parent: ?*Listing,
    total_size: usize = 0,

    fn fromDir(allocator: mem.Allocator, str: []const u8) mecha.Error!Listing {
        const res = try dir_line.parse(allocator, str);
        return .{
            .lt = .{ .dir = std.StringHashMap(Listing).init(allocator) },
            .name = try allocator.dupe(u8, res.value),
            .parent = null,
        };
    }

    fn fromFile(allocator: mem.Allocator, str: []const u8) mecha.Error!Listing {
        const res = try file_line.parse(allocator, str);
        return .{
            .lt = .{ .size = res.value.@"0" },
            .name = try allocator.dupe(u8, res.value.@"1"),
            .parent = null,
        };
    }

    fn node(self: *Listing) *Listing {
        return self;
    }
};

const dir = mecha.discard(mecha.string("dir"));
const dir_line = mecha.combine(.{ dir, ws, name });
const size = mecha.int(usize, .{});
const name = mecha.rest;
const file_line = mecha.combine(.{ size, ws, name });

const parse_dir = dir_line.asStr().convert(Listing.fromDir);
const parse_file = file_line.asStr().convert(Listing.fromFile);
const listing = mecha.oneOf(.{ parse_dir, parse_file });

const StatementListingTypeTag = enum {
    statement,
    listing,
};

const StatementListingType = union(StatementListingTypeTag) {
    statement: Statement,
    listing: Listing,
};

const parse_line = mecha.oneOf(.{
    statement,
    listing,
});

const ws = mecha.discard(mecha.many(mecha.oneOf(.{
    mecha.utf8.char(0x0020),
    mecha.utf8.char(0x000A),
    mecha.utf8.char(0x000D),
    mecha.utf8.char(0x0009),
}), .{ .collect = false }));

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const input: std.fs.File = try std.fs.cwd().openFile("src/day7/input.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var root: Listing = .{
        .lt = .{ .dir = std.StringHashMap(Listing).init(arena.allocator()) },
        .name = "/",
        .parent = null,
    };
    root.parent = &root;
    var active_node: *Listing = &root;

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // var parsed = (try parse_line.parse(arena.allocator(), line)).value;
        // var parsed = (try statement.parse(arena.allocator(), line));
        var parsed: StatementListingType = undefined;
        if (statement.parse(arena.allocator(), line)) |result| {
            parsed = .{ .statement = result.value };
        } else |_| {
            if (listing.parse(arena.allocator(), line)) |result| {
                parsed = .{ .listing = result.value };
            } else |_| {
                try stdout.print("ERROR Failed to parse: {s}\n", .{line});
            }
        }
        // try stdout.print("{}\n", .{parsed});
        // try bw.flush();

        switch (parsed) {
            StatementListingTypeTag.statement => {
                switch (parsed.statement.cmd) {
                    Command.cd => {
                        if (mem.eql(u8, parsed.statement.arg, "/")) {
                            active_node = &root;
                        } else if (mem.eql(u8, parsed.statement.arg, "..")) {
                            active_node = active_node.parent.?;
                        } else {
                            // Find the directory in the active dir list and change to it
                            if (active_node.lt == ListingTypeTag.dir) {
                                var node = active_node.lt.dir.getPtr(parsed.statement.arg);
                                if (node) |n| {
                                    // active_node = @constCast(&n);
                                    active_node = n;
                                }
                            }
                        }
                    },
                    Command.ls => {},
                }
            },
            StatementListingTypeTag.listing => {
                if (active_node.lt == ListingTypeTag.dir) {
                    parsed.listing.parent = active_node;
                    try active_node.lt.dir.put(parsed.listing.name, parsed.listing);
                }
            },
        }
    }

    var iter = root.lt.dir.keyIterator();
    while (iter.next()) |key| {
        var nobj = root.lt.dir.getPtr(key.*);
        if (nobj) |n| {
            root.total_size += try dir_dive(n, stdout);
        }
    }
    try stdout.print("Mystery Size {}\n", .{mystery_size});
    try stdout.print("Root total size: {}\n", .{root.total_size});

    const space_needed = 30000000 - (70000000 - root.total_size);
    try stdout.print("Need to find {} bytes of space\n", .{space_needed});
    kill_selection = &root;
    try dir_to_kill(&root, space_needed, stdout);
    try bw.flush(); // don't forget to flush!
}

var mystery_size: usize = 0;
fn dir_dive(obj: *Listing, out: anytype) !usize {
    switch (obj.lt) {
        ListingTypeTag.dir => {
            var ter = obj.lt.dir.keyIterator();
            while (ter.next()) |key| {
                var nobj = obj.lt.dir.getPtr(key.*);
                if (nobj) |n| {
                    obj.total_size += try dir_dive(n, out);
                }
            }
            if (obj.total_size <= 100000) {
                try out.print("obj {s}, size {}\n", .{ obj.name, obj.total_size });
                mystery_size += obj.total_size;
            }
        },
        ListingTypeTag.size => {
            obj.total_size = obj.lt.size;
        },
    }
    return obj.total_size;
}

var kill_selection: *Listing = undefined;
fn dir_to_kill(obj: *Listing, space_needed: usize, out: anytype) !void {
    switch (obj.lt) {
        ListingTypeTag.dir => {
            if (obj.total_size > space_needed) {
                if (obj.total_size < kill_selection.total_size) {
                    kill_selection = obj;
                    try out.print("selecting: {s}, size: {}\n", .{ kill_selection.name, kill_selection.total_size });
                }
                var ter = obj.lt.dir.keyIterator();
                while (ter.next()) |key| {
                    var nobj = obj.lt.dir.getPtr(key.*);
                    if (nobj) |n| {
                        // recurse and somehow return something useful
                        try dir_to_kill(n, space_needed, out);
                    }
                }
            }
        },
        ListingTypeTag.size => {},
    }
}
