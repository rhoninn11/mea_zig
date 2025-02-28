const std = @import("std");
const rl = @import("raylib");
const math = @import("../mods/core/math.zig");
const Allocator = std.mem.Allocator;

pub const AppMemory = struct {
    gpa: Allocator,
    arena: Allocator,
};

const InternalMain = *const fn (memory: *const AppMemory) void;

pub fn DeployInMemory(program: InternalMain) void {
    var fmt_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_arena = std.heap.ArenaAllocator.init(obj_gpa.allocator());
    defer {
        _ = obj_arena.deinit();
        _ = obj_gpa.deinit();
        _ = fmt_gpa.deinit();
    }

    const mm = AppMemory{
        .gpa = fmt_gpa.allocator(),
        .arena = obj_arena.allocator(),
    };

    program(&mm);
}

const fv2 = @import("../mods/core/math.zig").fv2;
pub const RLWindow = struct {
    corner: math.fv2,
    size: math.fv2,
};

pub const RenderMedium = union(enum) {
    rlwin: *RLWindow,
    rltex: rl.RenderTexture,

    pub fn begin(self: RenderMedium) void {
        // std.debug.print("elo\n", .{});
        switch (self) {
            RenderMedium.rlwin => rl.beginDrawing(),
            RenderMedium.rltex => |rltxt| rl.beginTextureMode(rltxt),
        }
    }

    pub fn end(self: RenderMedium) void {
        switch (self) {
            RenderMedium.rlwin => rl.endDrawing(),
            RenderMedium.rltex => rl.endTextureMode(),
        }
    }
};

pub fn windowed_program(mem: *const AppMemory) void {
    const screenWidth = 1600;
    const screenHeight = 900;
    var window = RLWindow{
        .corner = fv2{ screenWidth, 0 },
        .size = fv2{ screenWidth, screenWidth },
    };

    const title: [:0]const u8 = "+++ Runing simulation in a window +++";
    rl.initWindow(screenWidth, screenHeight, title.ptr);
    defer rl.closeWindow();
    ScenesModule.union_fn(mem, &window) catch {
        std.debug.print("error cleaning\n", .{});
    };
}

const fs = @import("../explore/filesystem.zig");

const geo = @import("scene_GlbToImg.zig");
const scene = @import("simpleScene2D.zig");
const ChessBoard = @import("scene_ChessBoardRender.zig");
const GlbPreview = @import("scene_GlbPreview.zig");

const Scenes = enum {
    chess_board,
    glb_preview,
    simple_2d_scene,
    glb_to_image,
};

// Would be nice if possible of course to call each scene fn with switch
const ScenesModule = union(Scenes) {
    const Self = @This();

    const asad = [_]type{ geo, scene, ChessBoard, GlbPreview };

    pub fn union_fn(allocator: *const AppMemory, window: *RLWindow) !void {
        const selected_scene = .chess_board;

        const a = switch (selected_scene) {
            .chess_board => ChessBoard.launchAppWindow(allocator, window),
            .glb_preview => GlbPreview.launchAppWindow(allocator, window),
            .simple_2d_scene => scene.launchAppWindow(allocator, window),
            else => return error.NotEnoughData,
        };

        a catch unreachable;

        // const filenames = try fs.getAllGlbs(aloc.gpa);
        // geo.external_glbs = filenames;
        // defer {
        //     for (filenames) |file| aloc.gpa.free(file);
        //     aloc.gpa.free(filenames);
        // }
        // try geo.launchAppWindow(aloc, win);
        // try scene.launchAppWindow(aloc, win);
        // try ChessBoard.launchAppWindow(aloc, win);
        // try GlbPreview.launchAppWindow(allocator, window);
    }
};
