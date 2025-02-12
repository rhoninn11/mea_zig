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
const vi2 = math.vi2;
const vf2 = math.vf2;
const i2f = math.i2f;

fn upVec() rl.Vector3 {
    return rl.Vector3.init(0, 0, 1);
}

pub const Circle = struct {
    const Self = @This();

    pos: vi2 = .{ 0, 0 },
    color: rl.Color = rl.Color.maroon,
    height: i32 = 100,
    sig: ?*Signal = null,

    pub fn setPos(self: *Self, new_pos: vi2) void {
        self.pos = new_pos;
    }

    pub fn draw(self: Self, osc: Osc) void {
        const osc_pos_f = osc.smple2D() * vf2{ 2.22, 2 };
        const osc_pos_i = vi2{ @intFromFloat(osc_pos_f[0]), @intFromFloat(osc_pos_f[1]) };

        const circle_pos = self.pos + osc_pos_i;
        var shadow_pos = self.pos + vi2{ 0, self.height };

        const mask = vi2{ 1, 0 };
        shadow_pos += osc_pos_i * mask;

        // rl.drawCircle(circle_pos[0], circle_pos[1], 20, self.color);
        const pos3D = rl.Vector3.init(i2f(circle_pos[0]), i2f(circle_pos[1]), 0);

        rl.drawCircle3D(pos3D, 20, upVec(), 0, self.color);
        rl.drawEllipse(shadow_pos[0], shadow_pos[1], 25, 5, THEME[1]);
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
