const std = @import("std");
const rl = @import("raylib");

const math = @import("math.zig");

pub const test_string = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHI\nJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmn\nopqrstuvwxyz{|}~¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓ\nÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷\nøùúûüýþÿ";
pub const pl_characters = "ąęźżółćń";

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
