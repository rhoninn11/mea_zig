const rl = @import("raylib");
const std = @import("std");
const protos = @import("../gen/comfy.pb.zig");

// simple debug info about image protbufer
pub fn infoAboutProtoImg(img_proto: *protos.Image) void {
    switch (img_proto.pixels) {
        .Owned => |hmm| std.debug.print("img pixel size: {d}\n", .{hmm.str.len}),
        else => {},
    }

    if (img_proto.info) |info| {
        const h = info.height;
        const w = info.height;
        std.debug.print("focused proto image size is ({d},{d})", .{ w, h });
    }
}

// read protofile with image
pub fn loadImage(aloc: *std.mem.Allocator, file: []const u8) !protos.Image {
    const MB = 1024 * 1024;
    const cwd = std.fs.cwd();
    const proto_form_file = try cwd.readFileAlloc(aloc.*, file, 4 * MB);
    defer aloc.free(proto_form_file);

    var img_proto = try protos.Image.decode(proto_form_file, aloc.*);
    infoAboutProtoImg(&img_proto);
    return img_proto;
}

// imgge protobuf as raylib image
fn imgProtoToRl(proto_img: *protos.Image) rl.Image {
    const proto_pixels = proto_img.pixels.Owned.str.ptr;
    return rl.Image{
        .data = @constCast(@ptrCast(proto_pixels)),
        .height = proto_img.info.?.height,
        .width = proto_img.info.?.width,
        .format = rl.PixelFormat.pixelformat_uncompressed_r8g8b8,
        .mipmaps = 0,
    };
}

// render of protobufer serialized image to png with raylib
pub fn protobufTest() !void {
    // memory core
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var aloc = gpa.allocator();
    var prot_img = try loadImage(&aloc, "fs/serdesdump");
    defer prot_img.deinit();

    const rl_img = imgProtoToRl(&prot_img);
    _ = rl.exportImage(rl_img, "fs/serdesdump.png");
    std.debug.print("...\n", .{});
}
