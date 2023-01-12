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

    const input: std.fs.File = try std.fs.cwd().openFile("src/day6/input.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();
    //var buf: [1024]u8 = undefined;

    const num_distinct = 14;
    var som = [_]u8{0} ** num_distinct;
    var fifo = std.fifo.LinearFifo(u8, std.fifo.LinearFifoBufferType.Slice).init(som[0..]);
    //fifo.init(som[0..]);
    defer fifo.deinit();

    var i: usize = 1;
    stream: while (in_stream.readByte()) |char| : (i += 1) {
        if (fifo.readableLength() == num_distinct) {
            _ = fifo.readItem().?;
        }
        try fifo.writeItem(char);
        if (i > num_distinct) {
            var x: u8 = 0;
            while (x < num_distinct) : (x += 1) {
                var y: u8 = 0;
                while (y < num_distinct) : (y += 1) {
                    if (y != x) {
                        if (som[x] == som[y]) {
                            continue :stream;
                        }
                    }
                }
            }
            break :stream;
        }
    } else |err| {
        std.debug.print("error: {}\n", .{err});
    }

    try stdout.print("Start of packet: {}\n", .{i});
    try stdout.print("packet: {s}\n", .{som[0..]});
    try bw.flush(); // don't forget to flush!
}
