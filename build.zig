const std = @import("std");

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

const std_compile = std.Build.Step.Compile;

// comptime fn Options(bld: *std.Build) type {
//     return struct {
//         .target = b.standardOptimizeOption(.{}),
//     };
// }
const std_target = std.Build.ResolvedTarget;
const std_opims = std.builtin.OptimizeMode;

const buildOptions = struct {
    target: std_target,
    optimod: std_opims,
};

fn build_options(bld: *std.Build) buildOptions {
    return buildOptions{
        .target = bld.standardTargetOptions(.{}),
        .optimod = bld.standardOptimizeOption(.{}),
    };
}

pub fn add_raylib(
    bld: *std.Build,
    exe: *std_compile,
    bld_opts: buildOptions,
) void {
    const raylib_dep = bld.dependency("raylib-zig", .{
        .target = bld_opts.target,
        .optimize = bld_opts.optimod,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);
}

pub fn app_build(b: *std.Build) !void {
    // const bld_c = b.option(bool, "client", "+++ build client app") orelse false;
    // const bld_e = b.option(bool, "editor", "+++ build editor app") orelse false;
    const alt = b.option(bool, "alt", "+++ build alternative program") orelse false;

    const file_main: []const u8 = "main.zig";
    const file_alt: []const u8 = "alt.zig";

    const src_file = if (alt) file_alt else file_main;
    const src_file_path = try std.fmt.allocPrint(b.allocator, "src/{s}", .{src_file});
    defer b.allocator.free(src_file_path);

    const bld_opts = build_options(b);

    const exe = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path(src_file_path),
        .target = bld_opts.target,
        .optimize = bld_opts.optimod,
    });

    const zig_img = b.dependency("zigimg", .{
        .target = bld_opts.target,
        .optimize = bld_opts.optimod,
    });
    exe.root_module.addImport("zigimg", zig_img.module("zigimg"));

    add_raylib(
        b,
        exe,
        bld_opts,
    );

    b.installArtifact(exe);

    // for run step you must run 'zig build run'
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "+++ run cli app after build");
    run_step.dependOn(&run_exe.step);
}

fn cpp_build_exp(b: *std.Build) !void {
    const bld_ops = build_options(b);

    const exe = b.addExecutable(.{
        .name = "app_cpp",
        .root_source_file = b.path("src/main.cpp"),
        .target = bld_ops.target,
        .optimize = bld_ops.optimod,
    });

    b.installArtifact(exe);

    // REDO: this is not how cpp is build with zig
}

pub fn build(b: *std.Build) void {
    app_build(b) catch std.debug.print("!!! build failed", .{});
    // cpp_build_exp(b) catch std.debug.print("!!! cpp build failed", {});
}
