const std = @import("std");

const Choice = enum(u8) {
    rock = 1, // A and X
    paper = 2, // B and Y
    scissors = 3, // C and Z

    pub fn fromByte(char: u8) Choice {
        return switch (char) {
            'A' => Choice.rock,
            'B' => Choice.paper,
            'C' => Choice.scissors,
            else => unreachable,
        };
    }

    pub fn fromStrat(strat: GameResult, them: Choice) Choice {
        return switch (strat) {
            .loss => switch (them) {
                .rock => Choice.scissors,
                .paper => Choice.rock,
                .scissors => Choice.paper,
            },
            .draw => them,
            .win => switch (them) {
                .rock => Choice.paper,
                .paper => Choice.scissors,
                .scissors => Choice.rock,
            },
        };
    }
};

const GameResult = enum(u8) {
    loss = 0,
    draw = 3,
    win = 6,

    /// Result of a given b's choice
    pub fn aFight(a: Choice, b: Choice) GameResult {
        if (a == b)
            return GameResult.draw;
        if (a == Choice.scissors and b == Choice.rock)
            return GameResult.loss;
        if (a == Choice.rock and b == Choice.scissors)
            return GameResult.win;
        if (@enumToInt(a) > @enumToInt(b))
            return GameResult.win;
        return GameResult.loss;
    }

    pub fn fromByte(char: u8) GameResult {
        return switch (char) {
            'X' => GameResult.loss,
            'Y' => GameResult.draw,
            'Z' => GameResult.win,
            else => unreachable,
        };
    }
};

const Tournament = struct {
    games_played: u16 = 0,
    lost: u16 = 0,
    draw: u16 = 0,
    win: u16 = 0,
    score: u32 = 0,

    fn playGame(self: *Tournament, strat: []u8) void {
        self.games_played += 1;

        if (strat.len == 3) {
            const them = Choice.fromByte(strat[0]);
            const us = Choice.fromStrat(GameResult.fromByte(strat[2]), them);
            const gr = GameResult.aFight(us, them);

            self.score += @enumToInt(gr) + @enumToInt(us);

            switch (gr) {
                GameResult.loss => self.lost += 1,
                GameResult.draw => self.draw += 1,
                GameResult.win => self.win += 1,
            }
        } else {
            std.debug.print("bad stratagy '{s}'", .{strat});
        }
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

    const input: std.fs.File = try std.fs.cwd().openFile("src/day2/input.txt", .{});
    defer input.close();

    const in_reader = input.reader();
    var buf_reader = std.io.bufferedReader(in_reader);
    var in_stream = buf_reader.reader();

    var tourney: Tournament = .{};
    var buf: [1024]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        tourney.playGame(line);
    }

    try stdout.print("Results of {d} games: win: {d}, loss: {d}, draw:{d}, total score: {d}\n", .{
        tourney.games_played,
        tourney.win,
        tourney.lost,
        tourney.draw,
        tourney.score,
    });

    try bw.flush(); // don't forget to flush!
}

test "GameResult.aFight" {
    try std.testing.expectEqual(GameResult.aFight(Choice.rock, Choice.rock), GameResult.draw);
    try std.testing.expectEqual(GameResult.aFight(Choice.rock, Choice.paper), GameResult.loss);
    try std.testing.expectEqual(GameResult.aFight(Choice.rock, Choice.scissors), GameResult.win);

    try std.testing.expectEqual(GameResult.aFight(Choice.paper, Choice.paper), GameResult.draw);
    try std.testing.expectEqual(GameResult.aFight(Choice.paper, Choice.scissors), GameResult.loss);
    try std.testing.expectEqual(GameResult.aFight(Choice.paper, Choice.rock), GameResult.win);

    try std.testing.expectEqual(GameResult.aFight(Choice.scissors, Choice.scissors), GameResult.draw);
    try std.testing.expectEqual(GameResult.aFight(Choice.scissors, Choice.rock), GameResult.loss);
    try std.testing.expectEqual(GameResult.aFight(Choice.scissors, Choice.paper), GameResult.win);
}
