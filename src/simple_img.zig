const std = @import("std");

// Stałe określające rozmiar obrazu i siatki
const SIZE = 128;
const CH_NUM = 3;
const GRID1_SPACING = 16;
const GRID2_SPACING = 32;
const GRID1_COLOR = 200; // jasnoszary
const GRID2_COLOR = 150; // ciemniejszy szary

const BMPFileHeader = packed struct {
    signature: u16 = 0x4D42, // 'BM' w little endian
    size: u32,
    reserved1: u16 = 0,
    reserved2: u16 = 0,
    pixel_offset: u32 = 54, // 14 + 40 (rozmiar obu nagłówków)
};

// Struktura nagłówka informacji o obrazie BMP
const BMPInfoHeader = packed struct {
    size: u32 = 40,
    width: i32,
    height: i32,
    planes: u16 = 1,
    bits_per_pixel: u16 = 24,
    compression: u32 = 0,
    image_size: u32,
    x_pixels_per_meter: i32 = 0,
    y_pixels_per_meter: i32 = 0,
    colors_used: u32 = 0,
    important_colors: u32 = 0,
};

const drawDashedLine = struct {
    fn idx_2d(along_axis: usize, pos: usize) usize {
        return along_axis * SIZE + pos;
    }

    fn set_pixel(buffer: []u8, idx: usize, color: u8) void {
        buffer[idx] = color;
        buffer[idx + 1] = color;
        buffer[idx + 2] = color;
    }
    fn horizontal(buffer: []u8, y: usize, color: u8) void {
        var x: usize = 0;
        while (x < SIZE) : (x += 1) {
            if ((x % 8) < 4) {
                const idx = CH_NUM * idx_2d(y, x);
                set_pixel(buffer, idx, color);
            }
        }
    }

    fn vertical(buffer: []u8, x: usize, color: u8) void {
        var y: usize = 0;
        while (y < SIZE) : (y += 1) {
            // Wzór kreskowany: 4 piksele on, 4 piksele off
            if ((y % 8) < 4) {
                const idx = (y * SIZE + x) * 3;
                set_pixel(buffer, idx, color);
            }
        }
    }
};

pub fn save_to_file(pixels: []u8, name: []const u8, img_size: usize, row_size: usize) !void {
    const file = try std.fs.cwd().createFile(name, .{});
    defer file.close();

    const file_header = BMPFileHeader{
        .size = @truncate(54 + img_size),
    };

    const info_header = BMPInfoHeader{
        .width = SIZE,
        .height = SIZE,
        .image_size = @truncate(img_size),
    };

    try file.writeAll(std.mem.asBytes(&file_header));
    try file.writeAll(std.mem.asBytes(&info_header));

    var row: usize = SIZE;
    while (row > 0) {
        row -= 1;
        const row_start = row * row_size;
        try file.writeAll(pixels[row_start .. row_start + row_size]);
    }
}

pub fn main() !void {
    // Alokator dla naszego programu
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Bufor na piksele (RGB dla każdego piksela)
    const pixels = try allocator.alloc(u8, SIZE * SIZE * 3);
    defer allocator.free(pixels);

    const row_size = ((SIZE * 3 + 3) / 4) * 4;
    const img_size = row_size * SIZE;

    // Wypełnij tło na biało
    @memset(pixels, 255);

    // Rysuj pierwszą siatkę (jaśniejszą)
    var i: usize = 0;
    while (i < SIZE) : (i += GRID1_SPACING) {
        drawDashedLine.horizontal(pixels, i, GRID1_COLOR);
        drawDashedLine.vertical(pixels, i, GRID1_COLOR);
    }

    // Rysuj drugą siatkę (ciemniejszą)
    i = 0;
    while (i < SIZE) : (i += GRID2_SPACING) {
        drawDashedLine.horizontal(pixels, i, GRID2_COLOR);
        drawDashedLine.vertical(pixels, i, GRID2_COLOR);
    }

    // Zapisz jako plik PPM
    try save_to_file(pixels, "file.bmp", img_size, row_size);
}
