const std = @import("std");
const CopyFileOptions = std.fs.Dir.CopyFileOptions;
const CreateFlags = std.fs.File.CreateFlags;
const OpenFlags = std.fs.File.OpenFlags;

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

    try std.testing.expect(false);
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

pub fn fs_explorer() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arean = std.heap.ArenaAllocator.init(gpa.allocator());
    defer _ = gpa.deinit();
    defer _ = arean.deinit();

    const name: []const u8 = "TRIDE";
    try envRefererence(arean.allocator(), name);
}

const Entry = std.fs.Dir.Entry;
fn isGlbFile(entry: *const Entry) bool {
    const name = entry.name;
    const is_file = entry.kind == .file;
    const is_glb = std.mem.endsWith(u8, name, ".glb");
    return is_glb and is_file;
}

fn envRefererence(alloc: std.mem.Allocator, env_name: []const u8) !void {
    var found = false;
    var fmt_memory: [1024:0]u8 = undefined;
    var result_buf: []u8 = fmt_memory[0..];
    {
        var env = try std.process.getEnvMap(alloc);
        defer env.deinit();
        var vars = env.iterator();
        while (vars.next()) |entry| {
            if (std.mem.eql(u8, entry.key_ptr.*, env_name)) {
                std.debug.print("+++ bingo\n", .{});
            }
            switch (std.mem.count(u8, entry.key_ptr.*, env_name)) {
                else => continue,
                1 => {
                    const os_dir = entry.value_ptr.*;
                    const dst_name = result_buf[0..os_dir.len];
                    @memcpy(dst_name, entry.value_ptr.*);
                    result_buf = dst_name;
                    found = true;
                    break;
                },
            }
        }
    }
    std.debug.assert(found);

    const ops_path = result_buf;
    var dir = try std.fs.openDirAbsolute(ops_path, .{ .iterate = true });
    defer dir.close();

    var dir_entries = dir.iterate();
    var glb_num: u32 = 0;
    var glb_size: u32 = 0;
    while (try dir_entries.next()) |entry| {
        if (isGlbFile(&entry)) {
            glb_size = @as(u32, @intCast(entry.name.len));
            glb_num += 1;
        }
    }

    const FileList = std.ArrayList([]u8);
    var glb_files = try FileList.initCapacity(alloc, glb_num);
    defer glb_files.deinit();

    dir_entries = dir.iterate();

    const file_path: []u8 = try alloc.alloc(u8, glb_size);
    defer alloc.free(file_path);
    while (try dir_entries.next()) |entry| {
        @memcpy(file_path, entry.name);
        const abs_path = try std.mem.join(alloc, "/", &[_][]u8{ ops_path, file_path });
        std.debug.print("glb num: {s} \n", .{abs_path});
    }
}
