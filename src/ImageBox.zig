const rl = @import("raylib");
const std = @import("std");

const Self = @This();
pub const Theme = @import("mods/core/repr.zig").Theme;
img: ?rl.Image = null,
img_gpu: ?rl.Texture2D = null,

fn exampleImage() rl.Image {
    const w = 128;
    const h = 128;

    const checker = rl.genImageChecked(w, h, 8, 8, Theme[0], Theme[1]);
    defer checker.unload();
    const checker_t2d = rl.loadTextureFromImage(checker);
    defer checker_t2d.unload();
    const buffer_t2d = rl.RenderTexture2D.init(w * 2, h * 2);
    defer buffer_t2d.unload();
    rl.beginTextureMode(buffer_t2d);
    rl.drawTexture(checker_t2d, w / 2, w / 2);
    rl.endTextureMode();

    rl.loadImageFromTexture(buffer_t2d);

    return checker;
}

pub fn saveImageTest() void {
    const img = exampleImage();
    _ = rl.exportImage(img, "fs/export.png");
}

pub fn imageLoadTry(self: *Self) void {
    const img = exampleImage();
    const h = img.height;
    const w = img.width;

    std.debug.print("Image loaded? w {d}, h {d}\n", .{ h, w });

    self.img = img;
    std.debug.print("halo\n", .{});
    self.img_gpu = rl.loadTextureFromImage(img);
}

pub fn repr(self: *Self) void {
    if (self.img_gpu) |tt2D|
        rl.drawTexture(tt2D, 300, 300, rl.Color.white);
}
