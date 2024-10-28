const std = @import("std");

pub fn build(b: *std.Build) void {
    build_cli(b);
}

pub fn wasm_target_build(b: *std.Build) void {
    const target = .{
        .cpu_arch = .wasam32,
        .os_tag = .freestanding,
    };

    const lib = b.addSharedLibrary(.{
        .name = "generic_name",
        .root_source_file = b.path("src/wasm.zig"),
        .target = target,
    });

    lib.rdynamic = true;
    lib.import_memory = true;
    lib.initial_memory = 65536 * 4;
    lib.max_memory = 65536 * 4;

    b.installArtifact(lib);
}

pub fn build_cli(b: *std.Build) void {
    // const bld_c = b.option(bool, "client", "+++ build client app") orelse false;
    // const bld_e = b.option(bool, "editor", "+++ build editor app") orelse false;
    // const bld_s = b.option(bool, "server", "+++ build server app") orelse false;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "checker_generator",
        .root_source_file = b.path("src/simple_img.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zig_img = b.dependency("zigimg", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zigimg", zig_img.module("zigimg"));
    b.installArtifact(exe);

    // for run step you must run 'zig build run'
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "+++ run cli app after build");
    run_step.dependOn(&run_exe.step);
}
