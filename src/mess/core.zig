const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");
const Allocator = std.mem.Allocator;

pub const AppMemory = struct {
    gpa: Allocator,
    arena: Allocator,
};

pub fn DeployInMemory() void {
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

    var window = RLWindow.init();
    defer rl.closeWindow();

    ScenesModule.union_fn(&mm, &window) catch {
        std.debug.print("error cleaning\n", .{});
    };
}

pub const RLWindow = struct {
    corner: math.fv2,
    size: math.fv2,

    pub fn init() RLWindow {
        const screenWidth = 1600;
        const screenHeight = 900;
        const window = RLWindow{
            .size = .{ screenWidth, screenWidth },
            .corner = .{ screenWidth, 0 },
        };

        const title: [:0]const u8 = "+++ Runing simulation in a window +++";
        rl.initWindow(screenWidth, screenHeight, title.ptr);
        return window;
    }
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

const Scenes = enum { chess_board, simple_2d_scene, with_glbs, springs };
// Would be nice if scenes ware discoverables
const ScenesModule = union(Scenes) {
    const fs = @import("../explore/filesystem.zig");
    const chess_board = @import("scene_ChessBoardRender.zig");
    const that_was_nawig_hmm = @import("scene_Simple2D.zig");
    const scene_with_glbs = @import("scene_GlbPreview.zig");
    const scene_with_springs = @import("scene_SpringSim.zig");
    // TODO: meaby in comptime i could find all specyfic files and create comptime union for them ?xD
    // but first enum for that union is neaded?
    const Self = @This();

    const asad = [_]type{ that_was_nawig_hmm, chess_board };

    a: asad[0],
    b: asad[1],

    pub fn union_fn(memories: *const AppMemory, window: *RLWindow) !void {
        const selected_scene = .chess_board;
        // could select

        const termination = switch (selected_scene) {
            .simple_2d_scene => that_was_nawig_hmm.launchAppWindow(memories, window),
            .chess_board => chess_board.launchAppWindow(memories, window),
            .with_glbs => scene_with_glbs.launchAppWindow(memories, window),
            .springs => scene_with_springs.launchAppWindow(memories, window),
            else => return {},
        };

        termination catch {
            std.debug.print("!!! errors cannot bublb up further\n", .{});
        };
    }
};
