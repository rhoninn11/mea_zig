const std = @import("std");
const CopyFileOptions = std.fs.Dir.CopyFileOptions;
const CreateFlags = std.fs.File.CreateFlags;
const OpenFlags = std.fs.File.OpenFlags;

const Entry = std.fs.Dir.Entry;
const Allocator = std.mem.Allocator;

fn ensurePath(path: []const u8) !void {
    const dirname_for = std.fs.path.dirname(path) orelse ".";
    try std.fs.cwd().makePath(dirname_for);
}

fn projFile(alloc: Allocator, path: []const u8) ![]u8 {
    const src_path = try std.fmt.allocPrint(alloc, "assets/{s}", .{path});
    defer alloc.free(src_path);
    const dst_path = try std.fmt.allocPrint(alloc, "fs/{s}", .{path});

    std.fs.cwd().access(dst_path, OpenFlags{}) catch {
        try ensurePath(dst_path);
        try std.fs.cwd().copyFile(src_path, std.fs.cwd(), dst_path, CopyFileOptions{});
    };

    return dst_path;
}

test "proj_assets_check" {
    const src_path = "assets/test.txt";
    const root_dir = std.fs.cwd();
    const content_file = try root_dir.createFile(src_path, CreateFlags{ .read = true });
    const test_data: []const u8 = "test contetnt is here";
    _ = try content_file.write(test_data);

    const dst_path = "fs/test.txt";
    const alloc = std.testing.allocator;

    const file_in_fs = try projFile(alloc, "test.txt");
    defer alloc.free(file_in_fs);

    try std.testing.expect(std.mem.eql(u8, dst_path, file_in_fs));
    try root_dir.access(file_in_fs, OpenFlags{});
    const check_file = try root_dir.openFile(file_in_fs, OpenFlags{ .mode = .read_only });

    const b_slice = try alloc.alloc(u8, 1024);
    defer alloc.free(b_slice);

    const len = try check_file.read(b_slice);
    const in_file_data = b_slice[0..len];
    try std.testing.expectEqualSlices(u8, test_data, in_file_data);

    try root_dir.deleteFile(src_path);
    try root_dir.deleteFile(dst_path);

    // A tu miało jeszcze coś powstać?
    try std.testing.expect(true);
}

const SimpleData = struct {
    name: []const u8,
};

fn jsonCreateAndSave() !void {
    const first_json = "fs/deeper/file.json";
    try ensurePath(first_json);
    const file = try std.fs.cwd().createFile(first_json, CreateFlags{ .read = true });
    defer file.close();

    std.debug.print("+++ file {s} create\n", .{first_json});

    const val = SimpleData{ .name = "adam grzelok" };

    const p_alloc = std.heap.page_allocator;
    const jstr_memory = try std.json.stringifyAlloc(p_alloc, val, .{});
    defer p_alloc.free(jstr_memory);

    std.debug.print("+++ result json string is {s}\n", .{jstr_memory});

    const res = try file.write(jstr_memory);
    std.debug.print("+++ what information is that {}\n", .{res});
}

// const ser = @import("serialization.zig");

fn promptFromJson() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    const prompt_file = try projFile(alloc, "prompt.json");
    defer alloc.free(prompt_file);

    // try ser.openPrompt(alloc, prompt_file)
}
// -----------------------------------------------------------------------------------------
fn fileEndsWith(entry: *const Entry, ext: []const u8) bool {
    const name = entry.name;
    const is_file = entry.kind == .file;
    const is_glb = std.mem.endsWith(u8, name, ext);
    return is_glb and is_file;
}

test "id extraction" {
    const samples = [_][]const u8{
        "*fs/tride/models/model_023.glb",
        "*fs/tride/models/model_00152.glb",
    };

    const results = [_]u32{ 23, 152 };
    for (samples, results) |sample, val| {
        try std.testing.expectEqual(val, try extractId(sample));
    }
}

fn extractId(full_path: []const u8) !u32 {
    const ext = ".glb";
    const digits = 3;

    const beg: usize = full_path.len - ext.len - digits;
    const end: usize = beg + digits;

    const digit_string = full_path[beg..end];
    return try std.fmt.parseInt(u32, digit_string, 10);
}

fn readEnvVar(alloc: std.mem.Allocator, var_name: []const u8) ![]u8 {
    var env = try std.process.getEnvMap(alloc);
    defer env.deinit();
    var vars = env.iterator();
    while (vars.next()) |entry| {
        if (std.mem.eql(u8, entry.key_ptr.*, var_name)) {
            const os_dir = entry.value_ptr.*;
            const dst_name = try alloc.alloc(u8, os_dir.len);
            @memcpy(dst_name, entry.value_ptr.*);
            return dst_name;
        }
    }
    @panic("!!! env variable do not exitsts");
}

pub fn fs_explorer() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arean = std.heap.ArenaAllocator.init(gpa.allocator());
    defer _ = gpa.deinit();
    defer _ = arean.deinit();

    _ = try envRefererence(gpa.allocator());
}

fn allFileFrom(alloc: Allocator, path: []const u8, file_ext: []const u8) ![][:0]u8 {
    const ops_path = path;
    var dir = try std.fs.openDirAbsolute(ops_path, .{ .iterate = true });
    defer dir.close();

    var glb_num: u32 = 0;
    var glb_size: u32 = 0;
    var dir_entries = dir.iterate();
    while (try dir_entries.next()) |entry| {
        if (fileEndsWith(&entry, file_ext)) {
            glb_size = @as(u32, @intCast(entry.name.len));
            glb_num += 1;
        }
    }

    const result_path_to_glbs: [][:0]u8 = try alloc.alloc([:0]u8, glb_num);
    const path_stencil: []u8 = try alloc.alloc(u8, glb_size);
    defer alloc.free(path_stencil);

    dir_entries = dir.iterate();
    while (try dir_entries.next()) |entry| {
        if (fileEndsWith(&entry, file_ext)) {
            const id = try extractId(entry.name);
            @memcpy(path_stencil, entry.name);
            result_path_to_glbs[id] = try std.mem.joinZ(alloc, "/", &[_][]const u8{ ops_path, path_stencil });
        }
    }
    return result_path_to_glbs;
}

fn filesInfo(alloc: Allocator, paths: [][:0]u8) !void {
    _ = alloc;
    const all_files = paths;
    var total_size: u64 = 0;
    for (all_files) |file| {
        std.debug.print("top level: {s}\n", .{file});
        const model_data_fs = try std.fs.openFileAbsolute(file, .{});
        total_size += try model_data_fs.getEndPos();
        model_data_fs.close();
    }

    // const data_blob = try alloc.alloc(u8, total_size);
    // defer alloc.free(data_blob);
    // var beg: u64 = 0;
    // var end: u64 = 0;
    // for (all_files) |flie| {
    //     const fd = try std.fs.openFileAbsolute(flie, .{});
    //     defer fd.close();
    //     end = beg + try fd.getEndPos();
    //     const dest = data_blob[beg..end];
    //     beg = end;

    //     _ = try fd.reader().readAll(dest);
    // }

    const K = 1024;
    const sizes = [_]u32{ K, K * K, K * K * K };
    const units = [_][]const u8{ "KB", "MB", "GB" };
    var total_size_f: f32 = 0;
    var unit: []const u8 = undefined;
    for (units, sizes) |_unit, _size| {
        total_size_f = @as(f32, @floatFromInt(total_size)) / @as(f32, @floatFromInt(_size));
        unit = _unit;
        if (total_size_f < @as(f32, @floatFromInt(K))) break;
    }
    std.debug.print("+++ file count: {d}\n+++ total size {d:.3} {s}\n", .{ all_files.len, total_size_f, unit });
}

const Gltf = @import("zgltf");

fn envRefererence(alloc: std.mem.Allocator) !void {
    const all_files = try getAllGlbs(alloc);
    defer {
        for (all_files) |file| alloc.free(file);
        alloc.free(all_files);
    }
    try filesInfo(alloc, all_files);
}

pub fn getAllGlbs(alloc: Allocator) ![][:0]u8 {
    const env_name: []const u8 = "TRIDE";
    const root_dir = try readEnvVar(alloc, env_name);
    defer alloc.free(root_dir);
    return try allFileFrom(alloc, root_dir, ".glb");
}
