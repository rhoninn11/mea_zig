const std = @import("std");
const rl = @import("raylib");

pub fn logVec3(info: []const u8, v3: rl.Vector3) void {
    std.debug.print("+++ {s} Vec({d:.2}, {d:.2}, {d:.2})\n", .{ info, v3.x, v3.y, v3.z });
}
