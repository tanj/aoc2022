const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const input: std.fs.File = try std.fs.cwd().openFile("src/day4/input.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var fully_contained: u16 = 0;
    var overlap: u16 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var partners = try Partners.fromLine(line);
        if (partners.fullyContains()) {
            fully_contained += 1;
        }
        if (partners.overlaps()) {
            overlap += 1;
        }
    }

    try stdout.print("Assignment Pairs fully contain the other: {d}\n", .{fully_contained});
    try stdout.print("Assignment Pairs overlapping other: {d}\n", .{overlap});
    try bw.flush(); // don't forget to flush!
}

const Range = struct {
    lo: u16,
    hi: u16,

    fn fromSlice(slice: []const u8) !Range {
        var it = std.mem.tokenize(u8, slice, "-");
        return Range{
            .lo = try std.fmt.parseInt(u16, it.next().?, 10),
            .hi = try std.fmt.parseInt(u16, it.next().?, 10),
        };
    }

    fn fullyContains(self: *Range, other: *Range) bool {
        return self.isIn(other) or other.isIn(self);
    }

    fn isIn(self: *Range, other: *Range) bool {
        const lo_inside = (self.lo >= other.lo) and self.lo <= other.hi;
        const hi_inside = self.hi >= other.lo and self.hi <= other.hi;
        return lo_inside and hi_inside;
    }

    fn overlaps(self: *Range, other: *Range) bool {
        const lo_inside = self.lo >= other.lo and self.lo <= other.hi;
        const hi_inside = self.hi >= other.lo and self.hi <= other.hi;

        return lo_inside or hi_inside;
    }
};

const Partners = struct {
    one: Range,
    two: Range,

    fn fromLine(line: []const u8) !Partners {
        var it = std.mem.tokenize(u8, line, ",");
        return Partners{
            .one = try Range.fromSlice(it.next().?),
            .two = try Range.fromSlice(it.next().?),
        };
    }

    fn fullyContains(self: *Partners) bool {
        return self.one.fullyContains(&self.two);
    }

    fn overlaps(self: *Partners) bool {
        return self.one.overlaps(&self.two) or self.two.overlaps(&self.one);
    }
};
