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
    dir: bool,
    size: usize,
};

const Listing = struct {
    lt: ListingType,
    name: []const u8,

    fn fromDir(allocator: mem.Allocator, str: []const u8) mecha.Error!Listing {
        const res = try dir_line.parse(allocator, str);
        return .{
            .lt = .{ .dir = true },
            .name = res.value,
        };
    }

    fn fromFile(allocator: mem.Allocator, str: []const u8) mecha.Error!Listing {
        const res = try file_line.parse(allocator, str);
        return .{
            .lt = .{ .size = res.value.@"0" },
            .name = res.value.@"1",
        };
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
        try stdout.print("{}\n", .{parsed});
        try bw.flush();
    }

    try stdout.print("Start of packet: {}\n", .{1});
    try bw.flush(); // don't forget to flush!
}
