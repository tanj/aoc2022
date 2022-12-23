const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const day1_exe = b.addExecutable("aoc-day1", "src/day1/main.zig");
    day1_exe.setTarget(target);
    day1_exe.setBuildMode(mode);
    day1_exe.install();

    const day2_exe = b.addExecutable("aoc-day2", "src/day2/main.zig");
    day2_exe.setTarget(target);
    day2_exe.setBuildMode(mode);
    day2_exe.install();

    const day3_exe = b.addExecutable("aoc-day3", "src/day3/main.zig");
    day3_exe.setTarget(target);
    day3_exe.setBuildMode(mode);
    day3_exe.install();

    const day4_exe = b.addExecutable("aoc-day4", "src/day4/main.zig");
    day4_exe.setTarget(target);
    day4_exe.setBuildMode(mode);
    day4_exe.install();

    const day5_exe = b.addExecutable("aoc-day5", "src/day5/main.zig");
    day5_exe.setTarget(target);
    day5_exe.setBuildMode(mode);
    day5_exe.install();

    const run_cmd = day1_exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/day2/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
