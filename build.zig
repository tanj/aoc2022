const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const mecha = b.createModule(.{
        //.name = "mecha",
        .source_file = .{ .path = "../mecha/mecha.zig" },
        .dependencies = &.{},
    });

    const day1_exe = b.addExecutable(.{
        .name = "aoc-day1",
        .root_source_file = .{ .path = "src/day1/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    day1_exe.install();

    const day2_exe = b.addExecutable(.{
        .name = "aoc-day2",
        .root_source_file = .{ .path = "src/day2/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    day2_exe.install();

    const day3_exe = b.addExecutable(.{
        .name = "aoc-day3",
        .root_source_file = .{ .path = "src/day3/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    day3_exe.install();

    const day4_exe = b.addExecutable(.{
        .name = "aoc-day4",
        .root_source_file = .{ .path = "src/day4/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    day4_exe.install();

    const day5_exe = b.addExecutable(.{
        .name = "aoc-day5",
        .root_source_file = .{ .path = "src/day5/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    day5_exe.install();

    const day6_exe = b.addExecutable(.{
        .name = "aoc-day6",
        .root_source_file = .{ .path = "src/day6/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    day6_exe.install();

    const day7_exe = b.addExecutable(.{
        .name = "aoc-day7",
        .root_source_file = .{ .path = "src/day7/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    day7_exe.addModule("mecha", mecha);
    day7_exe.install();

    const run_cmd = day1_exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/day2/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
