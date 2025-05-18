const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");

const Color = rl.Color;

pub fn Dubble(thick: comptime_int) type {
    const DData = struct {
        const Self = @This();
        const border_thickness = thick;
        offsets: []const math.ivec2 = &.{
            .{ 0, thick },
            .{ thick, thick },
            .{ thick, 0 },
            .{ thick, -thick },
            .{ 0, -thick },
            .{ -thick, -thick },
            .{ -thick, 0 },
            .{ -thick, thick },
        },
    };

    const DubbleText = struct {
        const Self = @This();
        dd: DData = DData{},

        // realizing borders for sdf fonts can be way easiers
        // https://www.raylib.com/examples.html - sdf example here
        // https://youtu.be/1b5hIMqz_wM?si=UmM0R5uo4pTvff_C - about sdf method
        // https://steamcdn-a.akamaihd.net/apps/valve/2007/SIGGRAPH2007_AlphaTestedMagnification.pdf - seminal paper
        pub fn repr(self: Self, text: [:0]const u8, spot: math.ivec2, fontSize: i32, color: [2]Color) void {
            for (self.dd.offsets) |delta| {
                const dst = spot + delta;
                rl.drawText(text, dst[0], dst[1], fontSize, color[0]);
            }
            rl.drawText(text, spot[0], spot[1], fontSize, color[1]);
        }
    };

    const DubbleRect = struct {
        const Self = @This();
        dd: DData = DData{},
        pub fn repr(self: Self, spot: math.ivec2, size: math.ivec2, color: [2]Color) void {
            for (self.dd.offsets) |delta| {
                const dst = spot + delta;
                rl.drawRectangle(dst[0], dst[1], size[0], size[1], color[0]);
            }
            rl.drawRectangle(spot[0], spot[1], size[0], size[1], color[1]);
        }
    };

    return struct {
        pub const text = DubbleText{};
        pub const rect = DubbleRect{};
    };
}

pub const default = Dubble(2);
