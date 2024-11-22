const std = @import("std");
const Flags = std.fs.File.CreateFlags;

test "how to spliting works" {
    const name_a: []const u8 = "elo.txt";
    const name_b: []const u8 = "fs/dir/elo.txt";

    var iter_a = std.mem.split(u8, name_a, "/");

    while (iter_a.next()) |elem| {
        try std.testing.expectEqual(name_a, elem);
    }

    var iter_b = std.mem.split(u8, name_b, "/");
    const eql = std.mem.eql;
    const expect = std.testing.expect;

    const names: [3][]const u8 = .{ "fs", "dir", "elo.txt" };

    for (names) |name| {
        const chunk = iter_b.next() orelse "";
        try expect(eql(u8, name, chunk));
    }
}

fn ensurePath(path: []const u8) !void {
    const dirname_for = std.fs.path.dirname(path) orelse ".";
    std.debug.print("+++ dirname part is {s}\n", .{dirname_for});
    try std.fs.cwd().makePath(dirname_for);
}

test "path ensure test" {
    // tylko nie wiem jak sprawdzać czy plik istniej xD
}

const SimpleData = struct {
    name: []const u8,
};

pub fn fs_explorer() !void {
    try jsonCreateAndSave();
}

fn jsonCreateAndSave() !void {
    const first_json = "fs/deeper/file.json";
    try ensurePath(first_json);
    const file = try std.fs.cwd().createFile(first_json, Flags{ .read = true });
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
