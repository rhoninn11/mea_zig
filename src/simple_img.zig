const std = @import("std");
const zigimg = @import("zigimg");

// Stałe określające rozmiar obrazu i siatki
const SIZE = 128;
const CH_NUM = 3;

const ImgSize = struct {
    x: usize,
    y: usize,
    ch: usize,
    fn totalBytes(self: *const ImgSize) usize {
        return self.x * self.y * self.ch;
    }
};

const Img = struct {
    pixels: []u8,
    img_size: ImgSize,
};

const DrawDashedLine = struct {
    fn calc2DIdx(x: usize, y: usize, img_size: ImgSize) usize {
        return (y * img_size.x + x) * img_size.ch;
    }

    fn set_pixel(buffer: []u8, idx: usize, color: u8) void {
        buffer[idx] = color;
        buffer[idx + 1] = color;
        buffer[idx + 2] = color;
    }

    fn horizontal(img: Img, y: usize, color: u8) void {
        var x: usize = 0;
        while (x < SIZE) : (x += 1) {
            if ((x % 8) < 4) {
                const mem_idx = calc2DIdx(y, x, img.img_size);
                set_pixel(img.pixels, mem_idx, color);
            }
        }
    }

    fn vertical(img: Img, x: usize, color: u8) void {
        var y: usize = 0;
        while (y < SIZE) : (y += 1) {
            if ((y % 8) < 4) {
                const mem_idx = calc2DIdx(y, x, img.img_size);
                set_pixel(img.pixels, mem_idx, color);
            }
        }
    }
};

fn drawPattern(img: Img) void {
    const GRID1_SPACING = 16;
    const GRID2_SPACING = 32;
    const COLOR_LIGHT_GRAY = 200;
    const COLOR_DARK_GRAY = 150;


    var i: usize = 0;
    while (i < SIZE) : (i += GRID1_SPACING) {
        DrawDashedLine.horizontal(img, i, COLOR_LIGHT_GRAY);
        DrawDashedLine.vertical(img, i, COLOR_LIGHT_GRAY);
    }

    i = 0;
    while (i < SIZE) : (i += GRID2_SPACING) {
        DrawDashedLine.horizontal(img, i, COLOR_DARK_GRAY);
        DrawDashedLine.vertical(img, i, COLOR_DARK_GRAY);
    }
}

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

pub fn main() !void {
    // Alokator dla naszego programu
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const img_size = ImgSize{ .x = 128, .y = 128, .ch = 3};
    const pixels = try allocator.alloc(u8, img_size.totalBytes());
    defer allocator.free(pixels);

    @memset(pixels, 255);
    const img = Img{.pixels = pixels, .img_size = img_size};
    drawPattern(img);

    var z_img = try zigimg.Image.create(allocator, img_size.x, img_size.y, .rgb24);
    defer z_img.deinit();

    try simple_memory_scribes(allocator);

    const mem_proxy = std.mem.sliceAsBytes(z_img.pixels.rgb24);
    @memcpy(mem_proxy, pixels);
    try z_img.writeToFilePath("test.png", .{ .png = .{} });
}
