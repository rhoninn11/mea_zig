const std = @import("std");
const rl = @import("raylib");

const math = @import("math.zig");

pub const test_string = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI\nJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmn\nopqrstuvwxyz{|}~¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓ\nÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷\nøùúûüýþÿ";

const font_file = "assets/full_font.ttf";

pub fn getFont() rl.Font {
    const notimpl = true;
    return switch (notimpl) {
        true => rl.getFontDefault() catch unreachable,
        false => rl.loadFont(font_file) catch unreachable,
    };
}

pub fn inspectFont(font: *const rl.Font) void {
    const count: usize = @intCast(font.glyphCount);

    std.debug.print("+++ info: font {s} has {d} glypshs\n", .{ font_file, font.glyphCount });
    for (0..count) |i| {
        const a = &font.glyphs[i];
        const as_u8: u8 = @intCast(a.value);
        std.debug.print("+++ idx: {d}, val: {d}, render {c}\n", .{ i, a.value, as_u8 });
    }
}
const Color = rl.Color;
const thk = 2;
const deltas: []const math.ivec2 = &.{
    .{ 0, thk },
    .{ thk, thk },
    .{ thk, 0 },
    .{ thk, -thk },
    .{ 0, -thk },
    .{ -thk, -thk },
    .{ -thk, 0 },
    .{ -thk, thk },
};

pub fn DubbleFont(thickness: comptime_int) type {
    return struct {
        const Self = @This();
        thick: u8 = thickness,
        offsets: []const math.ivec2 = &.{
            .{ 0, thk },
            .{ thk, thk },
            .{ thk, 0 },
            .{ thk, -thk },
            .{ 0, -thk },
            .{ -thk, -thk },
            .{ -thk, 0 },
            .{ -thk, thk },
        },
        pub fn repr(self: Self, text: [:0]const u8, spot: math.ivec2, fontSize: i32, color: [2]Color) void {
            for (self.offsets) |delta| {
                const dst = spot + delta;
                rl.drawText(text, dst[0], dst[1], fontSize, color[0]);
            }
            rl.drawText(text, spot[0], spot[1], fontSize, color[1]);
        }
    };
}
