const rl = @import("raylib");
const std = @import("std");

const Vec2i = @import("_math.zig").Vec2i;
const Osc = @import("_osc.zig").Osc;

pub const THEME = [_]rl.Color{ rl.Color.black, rl.Color.beige };

pub const Circle = struct {
    pos: Vec2i,
    color: rl.Color,
    height: i32,

    pub fn basicCircle() Circle {
        return Circle{
            .pos = .{ .x = 100, .y = 100 },
            .color = rl.Color.maroon,
            .height = 100,
        };
    }

    pub fn draw(self: Circle, osc: Osc) void {
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

    pub fn setColor(self: *Circle, c: rl.Color) void {
        self.color = c;
    }
};
