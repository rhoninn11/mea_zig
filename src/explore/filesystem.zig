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

pub fn fs_explorer() !void {
    const dir = "fs";
    try std.fs.cwd().makePath(dir);

    const dir_ = "fs/fs_1/fs_2/fs_3";
    const dir_1 = "fs/fs_1/c/file.json";
    try std.fs.cwd().makePath(dir_);
    try std.fs.cwd().makePath(dir_1);

    const file_name: []const u8 = "fs/idono.json";
    _ = try std.fs.cwd().createFile(file_name, Flags{ .read = true });
    std.debug.print("+++ file {s} create\n", .{file_name});
}
