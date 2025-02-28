const std = @import("std");
const rl = @import("raylib");

pub fn maxAxis(v3: rl.Vector3) f32 {
    var max: f32 = 0;
    const axis = [_]f32{ v3.x, v3.y, v3.z };
    for (axis) |val| max = if (max > val) max else val;
    return max;
}

test "max axis" {
    const sample = rl.Vector3.init(1.2, 3.1, 2.1);
    try std.testing.expectEqual(maxAxis(sample), 3.1);
}

pub fn debugVec3(name: []const u8, v3: rl.Vector3) void {
    std.debug.print("+++ {s} Vec({d:.2}, {d:.2}, {d:.2})\n", .{ name, v3.x, v3.y, v3.z });
}
