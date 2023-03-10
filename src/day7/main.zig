const std = @import("std");
const mecha = @import("mecha");

const Command = enum {
    cd,
    ls,
};

const prompt = mecha.discard(mecha.string("$ "));
const cmd = mecha.enumeration(Command);
const arg = mecha.rest;

const Statement = struct {
    cmd: Command,
    arg: []const u8,
};

const statement = mecha.map(
    Statement,
    mecha.toStruct(Statement),
    mecha.combine(.{ prompt, cmd, mecha.opt(ws), arg }),
);

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

    fn fromDir(res: dir_line) Listing {
        return .{
            .lt = .{ .dir = true },
            .name = res.value,
        };
    }

    fn fromFile(res: file_line) Listing {
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

const parse_dir = mecha.map(Listing, Listing.fromDir, dir_line);
const parse_file = mecha.map(Listing, Listing.fromFile, file_line);
const listing = undefined;

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
        _ = line;
    }

    try stdout.print("Start of packet: {}\n", .{1});
    try bw.flush(); // don't forget to flush!
}
