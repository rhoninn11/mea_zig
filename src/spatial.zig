const std = @import("std");
const math = @import("mods/core/math.zig");
const calcProgress = math.calcProgres;

pub const LineOpts = struct {
    len: usize = 10,
    first: bool = true,
    last: bool = true,
};

fn _line1D(comptime len: u32) [len]f32 {
    var result: [len]f32 = undefined;
    for (0..len) |i| {
        const idx: u32 = @intCast(i);
        result[i] = calcProgress(idx, len, true);
    }
    return result;
}

pub fn line1D(comptime prog_ops: LineOpts) [prog_ops.len]f32 {
    comptime var padded_len = prog_ops.len;
    const fOff = if (prog_ops.first) 0 else 1;
    if (prog_ops.first == false) padded_len += 1;
    if (prog_ops.last == false) padded_len += 1;

    return trim_blk: {
        const nu32 = @as(u32, padded_len);
        const end2end = _line1D(nu32);

        var sub: [prog_ops.len]f32 = undefined;
        for (0..prog_ops.len) |idx| {
            sub[idx] = end2end[fOff + idx];
        }
        break :trim_blk sub;
    };
}

test "linProg test" {
    var elo = line1D(LineOpts{ .len = 10 });
    try std.testing.expect(elo.len == 10);
    try std.testing.expectEqual(elo[0], 0);
    try std.testing.expectEqual(elo[1], 1);

    elo = line1D(LineOpts{ .len = 10, .last = false });
    try std.testing.expect(elo.len == 10);
    try std.testing.expect(elo[9] < 0.99);
    try std.testing.expectEqual(elo[0], 0);

    elo = line1D(LineOpts{ .len = 10, .first = false, .last = false });
    try std.testing.expect(elo.len == 10);
    try std.testing.expect(elo[0] > 0.99);
    try std.testing.expect(elo[9] < 0.99);
}

const f2i = math.f2i;
const vi2 = math.iv2;
const vf2 = math.fv2;

pub const DynLinSpace = struct {
    a: vf2 = @splat(0),
    b: vf2 = @splat(0),

    pub fn sample(self: DynLinSpace, cords: f32) vf2 {
        const fac: vf2 = @splat(1 - cords);
        const rest: vf2 = @splat(cords);

        return self.a * fac + self.b * rest;
    }
};

pub const LinePreset = enum {
    Full,
    NoTip,
    NoLast,
    NoFirst,
};

pub fn LinStage(comptime len: u32, comptime kind: LinePreset) [len]f32 {
    const with_tips = LineOpts{ .len = len, .first = true, .last = true };
    const no_tips = LineOpts{ .len = len, .first = false, .last = false };
    const no_first_tip = LineOpts{ .len = len, .first = false, .last = true };
    const no_last_tip = LineOpts{ .len = len, .first = true, .last = false };

    comptime var setup: LineOpts = undefined;
    switch (kind) {
        LinePreset.Full => setup = with_tips,
        LinePreset.NoTip => setup = no_tips,
        LinePreset.NoFirst => setup = no_first_tip,
        LinePreset.NoLast => setup = no_last_tip,
    }

    return line1D(setup);
}
