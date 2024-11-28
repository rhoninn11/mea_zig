const rl = @import("raylib");
const std = @import("std");

const Osc = @import("osc.zig").Osc;

const Signal = @import("InputModule.zig").Signal;

pub const THEME = [_]rl.Color{ rl.Color.black, rl.Color.beige };

fn color_switch(b: bool) rl.Color {
    return switch (b) {
        false => rl.Color.maroon,
        true => rl.Color.dark_purple,
    };
}

const vi2 = @import("math.zig").vi2;

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
        const x: i32 = @intFromFloat(std.math.cos(osc.phase) * osc.amp * 2.22);
        const y: i32 = @intFromFloat(std.math.sin(osc.phase) * osc.amp * 2);
        const osc_pos = vi2{ x, y };

        const circle_pos = self.pos + osc_pos;
        var shadow_pos = self.pos + vi2{ 0, self.height };

        const mask = vi2{ 1, 0 };
        shadow_pos += osc_pos * mask;

        rl.drawCircle(circle_pos[0], circle_pos[1], 20, self.color);
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
};
