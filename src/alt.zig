const std = @import("std");
const zigimg = @import("zigimg");

const s_img = @import("simple_img.zig");

fn simple_memory_scribes(my_alloc: std.mem.Allocator) !void {
    const buffer_1 = try my_alloc.alloc(u8, 128);
    defer my_alloc.free(buffer_1);
    const buffer_2 = try my_alloc.alloc(u8, 128);
    defer my_alloc.free(buffer_2);

    @memset(buffer_1, 0xff);
    @memset(buffer_2, 0x00);

    std.debug.print("+++ buffer value before copy - {}\n", .{buffer_2[0]});
    @memcpy(buffer_2, buffer_1);
    std.debug.print("+++ buffer value after copy - {}\n", .{buffer_2[0]});
}

const SIZE = 128;
const CH_NUM = 3;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const img_size = s_img.ImgSize{ .x = SIZE, .y = SIZE, .ch = CH_NUM };
    const pixels = try allocator.alloc(u8, img_size.totalBytes());
    defer allocator.free(pixels);

    @memset(pixels, 255);
    const img = s_img.Img{ .pixels = pixels, .img_size = img_size };
    s_img.drawPattern(img);

    var z_img = try zigimg.Image.create(allocator, img_size.x, img_size.y, .rgb24);
    defer z_img.deinit();

    try simple_memory_scribes(allocator);

    const mem_proxy = std.mem.sliceAsBytes(z_img.pixels.rgb24);
    @memcpy(mem_proxy, pixels);
    try z_img.writeToFilePath("test.png", .{ .png = .{} });
}
