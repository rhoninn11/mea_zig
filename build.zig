const std = @import("std");
const protobuf = @import("protobuf");

const Compile = std.Build.Step.Compile;
const Dependency = std.Build.Dependency;

var scope_build: ?*std.Build = null;
var scope_target: ?std.Build.ResolvedTarget = null;
var scope_optimize: ?std.builtin.OptimizeMode = null;

var scratchpad: [1024]u8 = undefined;

fn initScopeOptions(b: *std.Build) void {
    scope_build = b;
    scope_target = b.standardTargetOptions(.{});
    scope_optimize = b.standardOptimizeOption(.{});
}

fn exe_test_tupla(root_file: []const u8) [2]*Compile {
    var tupla: [2]*Compile = undefined;
    const b = scope_build.?;
    tupla[0] = b.addExecutable(.{
        .name = "app",
        .root_source_file = b.path(root_file),
        .target = scope_target.?,
        .optimize = scope_optimize.?,
    });

    tupla[1] = b.addTest(.{
        .root_source_file = b.path(root_file),
        .target = scope_target.?,
        .optimize = scope_optimize.?,
    });
    return tupla;
}

fn addDependency(b: *std.Build, compileUnit: *Compile, name: []const u8) *Dependency {
    const dep = b.dependency(name, .{
        .target = scope_target.?,
        .optimize = scope_optimize.?,
    });

    compileUnit.root_module.addImport(name, dep.module(name));
    return dep;
}

pub fn addRaylib(b: *std.Build, exe: *Compile) void {
    const rlz = @import("raylib-zig");
    const target = scope_target.?;
    const is_wasm = target.result.cpu.arch == .wasm32;
    const gl_ver: rlz.OpenglVersion = if (is_wasm) .gles_3 else .auto;

    const raylib_dep = b.dependency("raylib-zig", .{
        .target = scope_target.?,
        .optimize = scope_optimize.?,
        .opengl_version = gl_ver,
    });
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library
    raylib_artifact.defineCMacro("SUPPORT_MESH_GENERATION", null);

    if (is_wasm) {
        exe.entry = .disabled;
    }
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

pub fn generateProto(b: *std.Build, dep: *Dependency) void {
    const bld_flag = b.step("gen", "compilation of .proto file in proto/");

    const gen_step = protobuf.RunProtocStep.create(b, dep.builder, scope_target.?, .{
        .destination_directory = b.path("src/gen"),
        .source_files = &.{"proto/comfy.proto"},
        .include_directories = &.{},
    });

    bld_flag.dependOn(&gen_step.step);
}

// for next tryies with emscripten
// cmd: zig build -Dtarget=wasm32-emscripten --sysroot /opt/emsdk/upstream/emscripten
pub fn nativeApp(b: *std.Build, main_file: []const u8) !void {
    const compiles = exe_test_tupla(main_file);
    for (compiles) |c| {
        c.addIncludePath(b.path("src/explore/precompile/include/"));
        addRaylib(b, c);
    }

    const exe = compiles[0];
    // blu.addGltfModule(exe);
    _ = addDependency(b, exe, "zigimg");
    const pb = addDependency(b, exe, "protobuf");
    generateProto(b, pb);
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "+++ run cli app after build");
    run_step.dependOn(&run_exe.step);

    const tests = compiles[1];
    const test_exe = b.addRunArtifact(tests);
    const test_step = b.step("test", "+++ run unit tests");
    test_step.dependOn(&test_exe.step);

    const sys_cmd = b.addSystemCommand(&.{
        "echo",
        "+++ output content sample +++",
        ">",
        "zig-out/cmd_out.txt",
    });
    const sys_cmd_2 = b.addSystemCommand(&.{"echo"});
    sys_cmd_2.addArgs(&.{
        "+++ output content sample +++",
        ">",
        "zig-out/cmd_out.txt",
    });
    const cmd_step = b.step("cmd", "+++ run system command");
    cmd_step.dependOn(&sys_cmd_2.step);
    _ = sys_cmd;
}

// zig build -Dwasm --sysroot /opt/emsdk/upstream/emscripten
fn wasmLib(b: *std.Build, main_file: []const u8) !void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .emscripten,
    });

    const src_file_path = try std.fmt.allocPrint(b.allocator, "src/{s}", .{main_file});
    const fn_lib = b.addStaticLibrary(.{
        .name = "fns",
        .root_source_file = b.path(src_file_path),
        .target = target,
        .optimize = .Debug,
        .link_libc = true,
    });
    // <https://github.com/ziglang/zig/issues/8633>
    fn_lib.global_base = 6560;
    fn_lib.entry = .disabled;
    fn_lib.rdynamic = true;
    fn_lib.import_memory = true;
    fn_lib.stack_size = std.wasm.page_size;

    fn_lib.initial_memory = std.wasm.page_size * 2;
    fn_lib.max_memory = std.wasm.page_size * 2;

    const emcc = b.pathJoin(&.{ b.sysroot.?, "emcc" });
    const em_step = b.addSystemCommand(&.{emcc});
    em_step.addArgs(&.{
        "-sEXPORT_ES6",
    });
    em_step.addFileArg(fn_lib.getEmittedBin());

    em_step.step.dependOn(&fn_lib.step);
    b.default_step.dependOn(&em_step.step);
}

pub fn build(b: *std.Build) !void {
    initScopeOptions(b);
    const vanila_wasm = b.option(bool, "wasm", "+++ build alternative program") orelse false;

    if (vanila_wasm) {
        try wasmLib(b, "src/wasmfns.zig");
    } else {
        try nativeApp(b, "src/main.zig");
    }
}
