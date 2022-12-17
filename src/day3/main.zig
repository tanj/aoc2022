const std = @import("std");

fn priority(item: u8) u8 {
    if (item >= 'a') {
        // Lowercase item types a through z have priorities 1 through 26.
        return item - 'a' + 1;
    }
    // Uppercase item types A through Z have priorities 27 through 52.
    return item - 'A' + 27;
}

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
            return priority(item);
        }
    }
    std.debug.print("Line: {s}\n", .{line});
    std.debug.print("Failed to find a matched item in comp 1: {s} and comp 2: {s}\n", .{ comp_one, comp_two });
    return 0;
}

const ElfGroupError = error{
    BagFullError,
    NoBadgeFoundError,
};

const bagSize = 3;
const ElfGroup = struct {
    alloc: std.mem.Allocator,
    bags: [bagSize][]u8,
    // how do we move the data from line buffer to the allocator space and hold
    // the slices here?
    ixBag: u8,

    fn addToGroup(self: *ElfGroup, bag: []u8) !void {
        if (self.ixBag < bagSize) {
            self.bags[self.ixBag] = try std.mem.concat(self.alloc, u8, &[_][]const u8{bag});
            self.ixBag += 1;
            return;
        }
        return ElfGroupError.BagFullError;
    }

    fn resetGroup(self: *ElfGroup) void {
        for (self.bags) |bag| {
            self.alloc.free(bag);
        }
        self.ixBag = 0;
    }

    fn getGroupBadgePriority(self: *ElfGroup) !u8 {
        var set_one = std.AutoArrayHashMap(u8, void).init(self.alloc);
        defer set_one.deinit();

        var set_two = std.AutoArrayHashMap(u8, void).init(self.alloc);
        defer set_two.deinit();

        for (self.bags[0]) |item| {
            try set_one.put(item, {});
        }
        // collect intersection of bag 0 and bag 1 into set two
        for (self.bags[1]) |item| {
            if (set_one.contains(item)) {
                try set_two.put(item, {});
            }
        }

        for (self.bags[2]) |item| {
            if (set_two.contains(item)) {
                return priority(item);
            }
        }
        return ElfGroupError.NoBadgeFoundError;
    }
};

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
    var group_sum: u16 = 0;
    var elfGroup = ElfGroup{
        .alloc = arena.allocator(),
        .bags = undefined,
        .ixBag = 0,
    };
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        priority_sum += try process_line(arena.allocator(), line);
        if (elfGroup.ixBag < bagSize) {
            try elfGroup.addToGroup(line);
        } else {
            group_sum += try elfGroup.getGroupBadgePriority();
            elfGroup.resetGroup();
            try elfGroup.addToGroup(line);
        }
    }

    // need to add last group to sum
    group_sum += try elfGroup.getGroupBadgePriority();
    elfGroup.resetGroup();

    try stdout.print("Priority Sum: {d}\n", .{priority_sum});
    try stdout.print("Group Sum: {d}\n", .{group_sum});
    try bw.flush(); // don't forget to flush!
}
