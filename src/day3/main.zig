const std = @import("std");

fn process_line(allocator: std.mem.Allocator, line: []u8) !u8 {
    // The list of items for each rucksack is given as characters all on a
    // single line. A given rucksack always has the same number of items in each
    // of its two compartments, so the first half of the characters represent
    // items in the first compartment, while the second half of the characters
    // represent items in the second compartment.

    // make two slices for each half
    const half_len: u8 = @intCast(u8, line.len) / 2;
    const comp_one: []u8 = line[0..half_len];
    const comp_two: []u8 = line[half_len..line.len];

    var comp_one_set = std.AutoArrayHashMap(u8, void).init(allocator);
    defer comp_one_set.deinit();

    for (comp_one) |item| {
        try comp_one_set.put(item, {});
    }

    for (comp_two) |item| {
        if (comp_one_set.contains(item)) {
            // 'a' has higher numeric order than 'A' so check this first
            if (item >= 'a') {
                // Lowercase item types a through z have priorities 1 through 26.
                return item - 'a' + 1;
            }
            // Uppercase item types A through Z have priorities 27 through 52.
            return item - 'A' + 27;
        }
    }
    std.debug.print("Line: {s}\n", .{line});
    std.debug.print("Failed to find a matched item in comp 1: {s} and comp 2: {s}\n", .{ comp_one, comp_two });
    return 0;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    const input: std.fs.File = try std.fs.cwd().openFile("src/day3/input.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    var priority_sum: u16 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        priority_sum += try process_line(arena.allocator(), line);
    }

    try stdout.print("Priority Sum: {d}\n", .{priority_sum});
    try bw.flush(); // don't forget to flush!
}
