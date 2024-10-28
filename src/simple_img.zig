const std = @import("std");
const zigimg = @import("zigimg");

// Stałe określające rozmiar obrazu i siatki
const SIZE = 128;
const CH_NUM = 3;
const GRID1_SPACING = 16;
const GRID2_SPACING = 32;
const GRID1_COLOR = 200; // jasnoszary
const GRID2_COLOR = 150; // ciemniejszy szary

const BMPFileHeader = packed struct {
    signature: u16 = 0x4D42, // 'BM' w little endian
    file_size: u32,
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
    colors_important: u32 = 0,
};

const BMPColorHeader = packed struct {
    mask_red: u32 = 0x00ff0000,
    mask_grean: u32 = 0x00ff0000,
    mask_blue: u32 = 0x00ff0000,
    mask_alpha: u32 = 0x00ff0000,
    color_space_type: u32 = 0x73524742,
    unused: u32,
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
        .file_size = @truncate(54 + img_size),
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

fn checker_draw(pixels_to_draw: []u8) void {
    var i: usize = 0;
    while (i < SIZE) : (i += GRID1_SPACING) {
        drawDashedLine.horizontal(pixels_to_draw, i, GRID1_COLOR);
        drawDashedLine.vertical(pixels_to_draw, i, GRID1_COLOR);
    }

    // Rysuj drugą siatkę (ciemniejszą)
    i = 0;
    while (i < SIZE) : (i += GRID2_SPACING) {
        drawDashedLine.horizontal(pixels_to_draw, i, GRID2_COLOR);
        drawDashedLine.vertical(pixels_to_draw, i, GRID2_COLOR);
    }
}

pub fn main() !void {
    // Alokator dla naszego programu
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Bufor na piksele (RGB dla każdego piksela)
    const pixels = try allocator.alloc(u8, SIZE * SIZE * CH_NUM);
    defer allocator.free(pixels);

    const row_size = ((SIZE * 3 + 3) / 4) * 4;
    const img_size = row_size * SIZE;

    @memset(pixels, 255);
    checker_draw(pixels);

    try save_to_file(pixels, "file.bmp", img_size, row_size);
    std.debug.print("Hello World!\n", .{});

    var img = try zigimg.Image.create(allocator, SIZE, SIZE, .rgb24);
    defer img.deinit();

    try simple_memory_scribes(allocator);

    const mem_proxy = std.mem.sliceAsBytes(img.pixels.rgb24);
    std.debug.print("+++ proxy len - {}, data len- {}\n", .{ mem_proxy.len, pixels.len });
    @memcpy(mem_proxy, pixels);
    try img.writeToFilePath("test.png", .{ .png = .{} });
}
