const rl = @import("raylib");
const std = @import("std");

const Osc = @import("osc.zig").Osc;
const Signal = @import("input.zig").Signal;

pub const THEME = @import("core/repr.zig").Theme;

fn color_switch(b: bool) rl.Color {
    return switch (b) {
        false => rl.Color.maroon,
        true => rl.Color.dark_purple,
    };
}

const math = @import("core/math.zig");
const iv2 = math.iv2;
const fv2 = math.fv2;
const i2f = math.i2f;

fn upVec() rl.Vector3 {
    return rl.Vector3.init(0, 0, 1);
}

pub const Circle = struct {
    const Self = @This();

    posf: fv2 = @splat(0),
    color: rl.Color = rl.Color.maroon,
    below: fv2 = fv2{ 0, 100 },
    sig: ?*Signal = null,

    pub fn setPos(self: *Self, new_pos: fv2) void {
        self.posf = new_pos;
    }

    pub fn draw(self: Self, osc: Osc) void {
        const osc_pos = osc.smple2D() * fv2{ 2.22, 2 };

        const circle_pos_f = self.posf + osc_pos;
        var shadow_pos = self.posf + osc_pos * math.axisX;
        shadow_pos += self.below;

        const _3d_pos = rl.Vector3.init(circle_pos_f[0], circle_pos_f[1], 0);
        rl.drawCircle3D(_3d_pos, 20, upVec(), 0, self.color);
        const _2d_pos = math.fviv(shadow_pos);
        rl.drawEllipse(_2d_pos[0], _2d_pos[1], 25, 5, THEME[1]);
    }

    pub fn update(self: *Self) void {
        const sig_eval: bool = if (self.sig) |sig| sig.get() else false;
        self.setColor(sig_eval);
    }

    pub fn setColor(self: *Circle, opt: bool) void {
        self.color = switch (opt) {
            false => rl.Color.maroon,
            true => rl.Color.dark_purple,
        };
    }

    pub fn createN(comptime n: usize) [n]Self {
        const result: [n]Self = .{Self{}} ** n;
        return result;
    }
    // statics
    pub fn WireSignals(circle_arr: []Circle, sig_arr: []*Signal) void {
        for (circle_arr, sig_arr) |*circle, sig| circle.sig = sig;
    }
};
