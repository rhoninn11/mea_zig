const rl = @import("raylib");
const std = @import("std");

const Self = @This();

img: ?rl.Image = null,
img_gpu: ?rl.Texture2D = null,

pub fn imageLoadTry(self: *Self) void {
    const img = rl.loadImage("fs/img.png");
    const h = img.height;
    const w = img.width;

    std.debug.print("Image loaded? w {d}, h {d}\n", .{ h, w });

    self.img = img;
    std.debug.print("halo\n", .{});
    self.img_gpu = rl.loadTextureFromImage(img);
}

pub fn drawRepr(self: Self) void {
    if (self.img_gpu) |tt2D|
        rl.drawTexture(tt2D, 300, 300, rl.Color.white);
}
