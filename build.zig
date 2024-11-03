const std = @import("std");

pub fn build(b: *std.Build) void {
    build_cli(b) catch std.debug.print("build failed", .{});
}

pub fn wasm_target_build(b: *std.Build) void {
    const target = .{
        .cpu_arch = .wasam32,
        .os_tag = .freestanding,
    };

    const lib = b.addSharedLibrary(.{
        .name = "app",
        .root_source_file = b.path("src/wasm.zig"),
        .target = target,
    });

    lib.rdynamic = true;
    lib.import_memory = true;
    lib.initial_memory = 65536 * 4;
    lib.max_memory = 65536 * 4;

    b.installArtifact(lib);
}

pub fn build_cli(b: *std.Build) !void {
    // const bld_c = b.option(bool, "client", "+++ build client app") orelse false;
    // const bld_e = b.option(bool, "editor", "+++ build editor app") orelse false;
    const alt = b.option(bool, "alt", "+++ build alternative program") orelse false;

    const file_main: []const u8 = "main.zig";
    const file_alt: []const u8 = "alt.zig";

    const src_file = if (alt) file_alt else file_main;
    const src_file_path = try std.fmt.allocPrint(b.allocator, "src/{s}", .{src_file});
    defer b.allocator.free(src_file_path);

    std.debug.print("+++ from build string {s}\n", .{src_file_path});

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path(src_file_path),
        .target = target,
        .optimize = optimize,
    });

    const zig_img = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("zigimg", zig_img.module("zigimg"));

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    b.installArtifact(exe);

    // for run step you must run 'zig build run'
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "+++ run cli app after build");
    run_step.dependOn(&run_exe.step);
}
