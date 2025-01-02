const std = @import("std");
const math = @import("mods/math.zig");
const calcProgress = math.calcProgres;

pub const progOps = struct {
    len: usize = 10,
    first: bool = true,
    last: bool = true,
};

pub fn linProg(comptime prog_ops: progOps) [prog_ops.len]f32 {
    comptime var padded_len = prog_ops.len;
    const fOff = if (prog_ops.first) 0 else 1;
    if (prog_ops.first == false) padded_len += 1;
    if (prog_ops.last == false) padded_len += 1;

    return trim_blk: {
        const nu32 = @as(u32, padded_len);

        var end2end: [padded_len]f32 = undefined;
        for (0..padded_len) |i| {
            const idx: u32 = @intCast(i);
            end2end[i] = calcProgress(idx, nu32, true);
        }

        var sub: [prog_ops.len]f32 = undefined;
        for (0..prog_ops.len) |idx| {
            sub[idx] = end2end[fOff + idx];
        }
        break :trim_blk sub;
    };
}

test "linProg test" {
    var elo = linProg(progOps{ .len = 10 });
    try std.testing.expect(elo.len == 10);
    try std.testing.expectEqual(elo[0], 0);
    try std.testing.expectEqual(elo[1], 1);

    elo = linProg(progOps{ .len = 10, .last = false });
    try std.testing.expect(elo.len == 10);
    try std.testing.expect(elo[9] < 0.99);
    try std.testing.expectEqual(elo[0], 0);

    elo = linProg(progOps{ .len = 10, .first = false, .last = false });
    try std.testing.expect(elo.len == 10);
    try std.testing.expect(elo[0] > 0.99);
    try std.testing.expect(elo[9] < 0.99);
}
