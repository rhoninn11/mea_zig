const std = @import("std");
const rl = @import("raylib");
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
pub const RLWindow = @import("../Navig.zig").RLWindow;
pub const RenderMedium = union(enum) {
    window: *RLWindow,
    target: rl.RenderTexture,

    pub fn begin(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.beginDrawing(),
            RenderMedium.target => |rtxt| rl.beginTextureMode(rtxt),
        }
    }

    pub fn end(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.endDrawing(),
            RenderMedium.target => rl.endTextureMode(),
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
    union_fn(mem, &window) catch {
        std.debug.print("error cleaning\n", .{});
    };
}
fn union_fn(aloc: *const AppMemory, win: *RLWindow) !void {
    try not_defined(aloc, win);
    try particles(aloc, win);
}

const not_defined = @import("simpleGeoRender.zig").particles;
const particles = @import("../Navig.zig").particles;
