const std = @import("std");
const protobuf = @import("protobuf");

const Compile = std.Build.Step.Compile;
const Dependency = std.Build.Dependency;

var scope_b: ?*std.Build = null;
var scope_tar: ?std.Build.ResolvedTarget = null;
var scope_optim: ?std.builtin.OptimizeMode = null;
var scope_opts: ?BuildOptions = null;

const BuildOptions = struct {
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,

    pub fn init(b: *std.Build) BuildOptions {
        scope_tar = b.standardTargetOptions(.{});
        scope_optim = b.standardOptimizeOption(.{});
        scope_opts = BuildOptions{
            .target = scope_tar.?,
            .optimize = scope_optim.?,
        };
        return scope_opts.?;
    }
};

const BuildUnit = struct {
    bld: *std.Build,
    bldOpt: BuildOptions,

    pub fn init(b: *std.Build) BuildUnit {
        return BuildUnit{
            .bld = b,
            .bldOpt = BuildOptions.init(b),
        };
    }

    // there is no need for zgltf now
    // pub fn addGltfModule(self: BuildUnit, compileUnit: *Compile) void {
    //     const zgltf_path = "tmp/zgltf/src/main.zig";
    //     const zgltf_mod = self.bld.addModule("zgltf", .{ .root_source_file = self.bld.path(zgltf_path) });
    //     compileUnit.root_module.addImport("zgltf", zgltf_mod);
    // }

    pub fn addLib(self: BuildUnit, compileUnit: *Compile, name: []const u8) *Dependency {
        const b = self.bld;
        const dep = b.dependency(name, .{
            .target = scope_tar.?,
            .optimize = scope_optim.?,
        });

        compileUnit.root_module.addImport(name, dep.module(name));
        return dep;
    }
};

fn build_options(bld: *std.Build) BuildOptions {
    return BuildOptions.init(bld);
}

pub fn addRaylib(b: *std.Build, exe: *Compile) void {
    const raylib_dep = b.dependency("raylib-zig", scope_opts.?);
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    // put rest raylib libs "here"
    const lib_zoo: []const []const u8 = &.{
        "raylib",
        "raygui",
    };
    for (lib_zoo) |lib_name| {
        const module = raylib_dep.module(lib_name);
        exe.root_module.addImport(lib_name, module);
    }
    exe.linkLibrary(raylib_artifact);
}

pub fn generateProto(blu: BuildUnit, dep: *Dependency) void {
    const bld = blu.bld;
    const bldOpt = blu.bldOpt;

    const bld_flag = bld.step("gen", "compilation of .proto file in proto/");

    const gen_step = protobuf.RunProtocStep.create(bld, dep.builder, bldOpt.target, .{
        .destination_directory = bld.path("src/gen"),
        .source_files = &.{"proto/comfy.proto"},
        .include_directories = &.{},
    });

    bld_flag.dependOn(&gen_step.step);
}

pub fn exeTestTupla(bUnit: BuildUnit, for_file: []const u8) [2]*Compile {
    const b = bUnit.bld;
    const bOps = bUnit.bldOpt;

    var tupla: [2]*Compile = undefined;
    tupla[0] = bUnit.bld.addExecutable(.{
        .name = "app",
        .root_source_file = b.path(for_file),
        .target = bOps.target,
        .optimize = bOps.optimize,
    });

    tupla[1] = b.addTest(.{
        .root_source_file = b.path(for_file),
        .target = bOps.target,
        .optimize = bOps.optimize,
    });
    return tupla;
}

pub fn nativeApp(b: *std.Build, main_file: []const u8) !void {
    const main_src = try std.fmt.allocPrint(b.allocator, "src/{s}", .{main_file});
    defer b.allocator.free(main_src);

    const blu = BuildUnit.init(b);
    const compile_paths = exeTestTupla(blu, main_src);
    for (compile_paths) |compile| {
        compile.addIncludePath(b.path("src/explore/precompile/include/"));
        addRaylib(b, compile);
    }

    const exe = compile_paths[0];
    // blu.addGltfModule(exe);
    _ = blu.addLib(exe, "zigimg");
    const pb = blu.addLib(exe, "protobuf");
    generateProto(blu, pb);
    b.installArtifact(exe);
    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "+++ run cli app after build");
    run_step.dependOn(&run_exe.step);

    const tests = compile_paths[1];
    const test_exe = b.addRunArtifact(tests);
    const test_step = b.step("test", "+++ run unit tests");
    test_step.dependOn(&test_exe.step);
}

fn wasmApp(b: *std.Build, main_file: []const u8) !void {
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

pub fn appBuildSwitch(b: *std.Build) !void {
    // const bld_c = b.option(bool, "client", "+++ build client app") orelse false;
    // const bld_e = b.option(bool, "editor", "+++ build editor app") orelse false;
    const vanila_wasm = b.option(bool, "wasm", "+++ build alternative program") orelse false;

    if (vanila_wasm) {
        try wasmApp(b, "wasmfns.zig");
    } else {
        try nativeApp(b, "main.zig");
    }
}

pub fn build(b: *std.Build) void {
    appBuildSwitch(b) catch std.debug.print("!!! build failed", .{});
}
