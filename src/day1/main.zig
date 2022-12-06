const std = @import("std");
const parseInt = std.fmt.parseInt;

const ElfStats = struct {
    id: u8 = 0,
    min: u32 = 0,
    max: u32 = 0,
    total: u32 = 0,
    count: u8 = 0,

    fn add_calories(self: *ElfStats, calories: u32) void {
        self.total += calories;
        self.count += 1;
        if (calories > self.max)
            self.max = calories;
        if (calories < self.min or self.min == 0)
            self.min = calories;
    }

    fn reset(self: *ElfStats) void {
        self.min = 0;
        self.max = 0;
        self.total = 0;
        self.count = 0;
    }

    fn display(self: *ElfStats, out: anytype) !void {
        try out.print("count: {d}, min: {d}, max: {d}, total: {d}\n", .{
            self.count,
            self.min,
            self.max,
            self.total,
        });
    }

    fn process_summary(
        self: *ElfStats,
        elf_summary: *ElfStats,
        elf_record: *ElfStats,
        elf_count: u8,
    ) void {
        self.id = elf_count;
        if (self.min < elf_summary.min or elf_summary.min == 0) {
            elf_summary.min = self.min;
            elf_record.min = elf_count;
        }
        if (self.max > elf_summary.max) {
            elf_summary.max = self.max;
            elf_record.max = elf_count;
        }
        if (self.count > elf_summary.count) {
            elf_summary.count = self.count;
            elf_record.count = elf_count;
        }
        if (self.total > elf_summary.total) {
            elf_summary.total = self.total;
            elf_record.total = elf_count;
        }
    }
};

fn cmpTotal(context: void, a: ElfStats, b: ElfStats) bool {
    _ = context;
    if (a.total > b.total) {
        return true;
    }
    return false;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var elfs = std.ArrayList(ElfStats).init(arena.allocator());
    defer elfs.deinit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const input: std.fs.File = try std.fs.cwd().openFile("src/day1/input.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;
    var current_elf: ElfStats = .{};
    var elf_count: u8 = 0;
    var elf_record: ElfStats = .{};
    var elf_summary: ElfStats = .{};
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len > 0) {
            var calories: u32 = try parseInt(u32, line, 0);
            current_elf.add_calories(calories);
        } else {
            elf_count += 1;
            current_elf.process_summary(&elf_summary, &elf_record, elf_count);
            // add current elf to list of elves
            try elfs.append(current_elf);
            try stdout.print("Elf: {d}\n", .{elf_count});
            try current_elf.display(stdout);
            current_elf.reset();
        }
    }

    if (current_elf.total > 0) {
        elf_count += 1;
        current_elf.process_summary(&elf_summary, &elf_record, elf_count);
        // add current elf to list of elves
        try elfs.append(current_elf);
        try stdout.print("Elf: {d}\n", .{elf_count});
        try current_elf.display(stdout);
    }
    try stdout.print("Elf Records: ", .{});
    try elf_record.display(stdout);
    try stdout.print("Calorie Summary: ", .{});
    try elf_summary.display(stdout);

    var elf_slice = try elfs.toOwnedSlice();
    std.sort.sort(ElfStats, elf_slice, {}, cmpTotal);
    {
        var i: u8 = 0;
        var top_three_total: u32 = 0;
        while (i < 3) : (i += 1) {
            try stdout.print("Elf id: {d} {d}: with {d}\n", .{
                elf_slice[i].id,
                i + 1,
                elf_slice[i].total,
            });
            top_three_total += elf_slice[i].total;
        }
        try stdout.print("Top three total: {d}\n", .{top_three_total});
    }

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
