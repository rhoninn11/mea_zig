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

const f2i = math.vi2;
const vi2 = math.vi2;
const vf2 = math.vf2;

pub const LinSpace = struct {
    a: vf2 = @splat(0),
    b: vf2 = @splat(0),

    fn sample(self: LinSpace, cords: f32) vf2 {
        const fac: vf2 = @splat(1 - cords);
        const rest: vf2 = @splat(cords);

        return self.a * fac + self.b * rest;
    }

    fn sample_i(self: LinSpace, cords: f32) vi2 {
        const f_val = self.sample(cords);
        return vi2{ f2i(f_val[0]), f2i(f_val[1]) };
    }
};
