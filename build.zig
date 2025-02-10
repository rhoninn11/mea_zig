const std = @import("std");
const protobuf = @import("protobuf");

const Compile = std.Build.Step.Compile;
const Dependency = std.Build.Dependency;
const std_target = std.Build.ResolvedTarget;
const std_opims = std.builtin.OptimizeMode;

const buildOptions = struct {
    target: std_target,
    optimod: std_opims,
};

const BuildUnit = struct {
    bld: *std.Build,
    bldOpt: buildOptions,

    pub fn addLib(self: BuildUnit, compileUnit: *Compile, name: []const u8) *Dependency {
        const dep = self.bld.dependency(name, .{
            .target = self.bldOpt.target,
            .optimize = self.bldOpt.optimod,
        });

        compileUnit.root_module.addImport(name, dep.module(name));
        return dep;
    }
};

fn build_options(bld: *std.Build) buildOptions {
    return buildOptions{
        .target = bld.standardTargetOptions(.{}),
        .optimod = bld.standardOptimizeOption(.{}),
    };
}

pub fn add_raylib(bld: *std.Build, exe: *Compile, bld_opts: buildOptions) void {
    const raylib_dep = bld.dependency("raylib-zig", .{
        .target = bld_opts.target,
        .optimize = bld_opts.optimod,
    });

    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    exe.linkLibrary(raylib_artifact);
    const raylib = raylib_dep.module("raylib"); // main raylib module
    exe.root_module.addImport("raylib", raylib);

    const raygui = raylib_dep.module("raygui"); // raygui module
    exe.root_module.addImport("raygui", raygui);
}

pub fn generateProto(bld: *std.Build, dep: *Dependency, bldOpt: buildOptions) void {
    const bld_flag = bld.step("gen", "compilation of .proto file in proto/");

    const gen_step = protobuf.RunProtocStep.create(bld, dep.builder, bldOpt.target, .{
        .destination_directory = bld.path("src/gen"),
        .source_files = &.{"proto/comfy.proto"},
        .include_directories = &.{},
    });

    bld_flag.dependOn(&gen_step.step);
}

pub fn local_app(b: *std.Build, main_file: []const u8) !void {
    const src_file_path = try std.fmt.allocPrint(b.allocator, "src/{s}", .{main_file});
    defer b.allocator.free(src_file_path);

    const bld_opts = build_options(b);
    const bu = BuildUnit{ .bld = b, .bldOpt = bld_opts };

    const exe = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path(src_file_path),
        .target = bld_opts.target,
        .optimize = bld_opts.optimod,
    });

    const my_tests = b.addTest(.{
        .root_source_file = b.path(src_file_path),
        .target = bld_opts.target,
        .optimize = bld_opts.optimod,
    });

    _ = bu.addLib(exe, "zigimg");
    add_raylib(b, exe, bld_opts);
    const pb = bu.addLib(exe, "protobuf");
    generateProto(b, pb, bld_opts);

    add_raylib(b, my_tests, bld_opts);

    b.installArtifact(exe);

    // for run step you must run 'zig build run'
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "+++ run cli app after build");
    run_step.dependOn(&run_exe.step);

    const test_exe = b.addRunArtifact(my_tests);
    const test_step = b.step("test", "+++ run unit tests");
    test_step.dependOn(&test_exe.step);
}

fn wasm_lib(b: *std.Build, main_file: []const u8) !void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const src_file_path = try std.fmt.allocPrint(b.allocator, "src/{s}", .{main_file});
    const exe = b.addExecutable(.{
        .name = "fns",
        .root_source_file = b.path(src_file_path),
        .target = target,
        .optimize = .ReleaseSmall,
    });

    // <https://github.com/ziglang/zig/issues/8633>
    exe.global_base = 6560;
    exe.entry = .disabled;
    exe.rdynamic = true;
    exe.import_memory = true;
    exe.stack_size = std.wasm.page_size;

    exe.initial_memory = std.wasm.page_size * 2;
    exe.max_memory = std.wasm.page_size * 2;

    b.installArtifact(exe);
}

pub fn app_build(b: *std.Build) !void {
    // const bld_c = b.option(bool, "client", "+++ build client app") orelse false;
    // const bld_e = b.option(bool, "editor", "+++ build editor app") orelse false;
    const vanila_wasm = b.option(bool, "wasm", "+++ build alternative program") orelse false;

    if (vanila_wasm) {
        try wasm_lib(b, "wasmfns.zig");
    } else {
        try local_app(b, "main.zig");
    }
}

pub fn build(b: *std.Build) void {
    app_build(b) catch std.debug.print("!!! build failed", .{});
}
