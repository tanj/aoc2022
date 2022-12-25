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

    const input: std.fs.File = try std.fs.cwd().openFile("src/day5/input.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;

    const num_stacks = 10;
    // zero index as waste to not worry about off-by-one errors
    var stacks: [num_stacks]std.ArrayList(u8) = undefined;

    {
        comptime var ix = 0;
        inline while (ix < num_stacks) : (ix += 1) {
            stacks[ix] = std.ArrayList(u8).init(arena.allocator());
            defer stacks[ix].deinit();
        }
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (line.len == 0) break;
        // we are assuming width and spacing of stacks
        var ix: u16 = 1;
        var ixItem: u16 = 1;
        while (ix < num_stacks) : (ix += 1) {
            var item = line[ixItem];
            ixItem += 4;
            if (item >= 'A')
                try stacks[ix].append(item);
        }
    }
    // reverse stacks so we can use them as stacks
    {
        var ix: u16 = 1;
        while (ix < num_stacks) : (ix += 1) {
            // move items into temp stack (index 0)
            while (stacks[ix].popOrNull()) |item| {
                try stacks[0].append(item);
            }
            // take the values from the reversed items and append them to stack
            for (stacks[0].items) |item| {
                try stacks[ix].append(item);
            }
            // clear temp stack
            while (stacks[0].popOrNull()) |item| {
                _ = item;
            }
        }
    }

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // continue parsing moves
        var it = std.mem.tokenize(u8, line, "move from to");
        var move: i16 = try std.fmt.parseInt(i16, it.next().?, 10);
        var from: usize = try std.fmt.parseInt(usize, it.next().?, 10);
        var to: usize = try std.fmt.parseInt(usize, it.next().?, 10);

        while (move > 0) : (move -= 1) {
            try stacks[0].append(stacks[from].pop());
        }
        // this simulates moving slices, but super simple
        while (stacks[0].popOrNull()) |item| {
            try stacks[to].append(item);
        }
    }

    try display_stacks(stacks[1..]);
    try stdout.print("Top of stacks: ", .{});

    {
        var ix: u8 = 1;
        while (ix < num_stacks) : (ix += 1) {
            try stdout.print("{c}", .{stacks[ix].pop()});
        }
        try stdout.print("\n", .{});
    }
    try bw.flush(); // don't forget to flush!
}

fn display_stacks(stacks: []std.ArrayList(u8)) !void {
    for (stacks) |stack| {
        std.debug.print("{s}\n", .{stack.items});
    }
}
