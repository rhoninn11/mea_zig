const rl = @import("raylib");
const std = @import("std");

const Vec2i = @import("_math.zig").Vec2i;
const Osc = @import("_osc.zig").Osc;

const Signal = @import("modules/InputModule.zig").Signal;

pub const THEME = [_]rl.Color{ rl.Color.black, rl.Color.beige };

fn color_switch(b: bool) rl.Color {
    return switch (b) {
        false => rl.Color.maroon,
        true => rl.Color.dark_purple,
    };
}

pub const Circle = struct {
    const Self = @This();

    pos: Vec2i = .{ .x = 100, .y = 100 },
    color: rl.Color = rl.Color.maroon,
    height: i32 = 100,
    sig: ?*Signal = null,

    pub fn draw(self: Self, osc: Osc) void {
        const osc_pos = Vec2i{
            .x = @intFromFloat(std.math.cos(osc.phase) * osc.amp),
            .y = @intFromFloat(std.math.sin(osc.phase) * osc.amp * 2),
        };
        const circle_pos = self.pos.add(osc_pos);
        const shadow_pos = Vec2i{
            .x = circle_pos.x,
            .y = self.pos.y + self.height,
        };
        rl.drawCircle(circle_pos.x, circle_pos.y, 20, self.color);
        rl.drawEllipse(shadow_pos.x, shadow_pos.y, 30, 5, THEME[1]);
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
