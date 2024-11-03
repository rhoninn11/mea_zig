const std = @import("std");

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
        while (x < img.img_size.x) : (x += 1) {
            if ((x % 8) < 4) {
                const mem_idx = calc2DIdx(y, x, img.img_size);
                set_pixel(img.pixels, mem_idx, color);
            }
        }
    }

    fn vertical(img: Img, x: usize, color: u8) void {
        var y: usize = 0;
        while (y < img.img_size.y) : (y += 1) {
            if ((y % 8) < 4) {
                const mem_idx = calc2DIdx(y, x, img.img_size);
                set_pixel(img.pixels, mem_idx, color);
            }
        }
    }
};

pub fn drawPattern(img: Img) void {
    const GRID1_SPACING = 16;
    const GRID2_SPACING = 32;
    const COLOR_LIGHT_GRAY = 200;
    const COLOR_DARK_GRAY = 150;

    var i: usize = 0;
    const x = img.img_size.x;
    const y = img.img_size.y;
    while (i < x) : (i += GRID1_SPACING) {
        DrawDashedLine.horizontal(img, i, COLOR_LIGHT_GRAY);
        DrawDashedLine.vertical(img, i, COLOR_LIGHT_GRAY);
    }

    i = 0;
    while (i < y) : (i += GRID2_SPACING) {
        DrawDashedLine.horizontal(img, i, COLOR_DARK_GRAY);
        DrawDashedLine.vertical(img, i, COLOR_DARK_GRAY);
    }
}
