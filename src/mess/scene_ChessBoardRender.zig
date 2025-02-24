const std = @import("std");
const rl = @import("raylib");
const core = @import("core.zig");

const AppMemory = core.AppMemory;
const RLWindow = core.RLWindow;
const RenderMedium = core.RenderMedium;

const Timeline = @import("../mods/time.zig").Timeline;
const elems = @import("../mods/elements.zig");
const Exiter = elems.Exiter;
const THEME = @import("../mods/core/repr.zig").Theme;

fn render_model(alloc: *const std.mem.Allocator, on_medium: RenderMedium, exiter: *Exiter, timeline: *Timeline) !void {
    const center = rl.Vector3.init(0, 0, 0);
    var camera = rl.Camera{
        .up = rl.Vector3.init(0, 1, 0),
        .position = center,
        .target = center,
        .fovy = 60,
        .projection = rl.CameraProjection.camera_perspective,
    };
    camera.target = rl.Vector3.init(0, 1, 0);
    // view = camera.getMatrix();
    const camera_pos = rl.Vector3.init(2, 0.5, 0);
    camera.position = camera_pos;

    const xy = 8;
    const grid: []f32 = try alloc.alloc(f32, xy * xy);
    defer alloc.free(grid);
    for (0..xy) |x| grid[x] = 1;
    for (1..xy) |y| @memcpy(grid[0..xy], grid[xy * y .. xy * (y + 1)]);

    while (exiter.toContinue()) {
        exiter.update(timeline.tickMs());
        rl.updateCamera(&camera, rl.CameraMode.camera_custom);

        on_medium.begin();
        defer on_medium.end();

        rl.clearBackground(THEME[1]);

        rl.beginMode3D(camera);
        defer {
            rl.endMode3D();
            exiter.draw();
        }

        const pos = rl.Vector3.init(0, 0, 0);
        rl.drawCube(pos, 1, 0.33, 1, rl.Color.white);
    }

    // rl.drawModel(model, center, 1, rl.Color.gray);

}
pub fn launchAppWindow(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    // const text_alloc = aloc.gpa;
    var on_medium: RenderMedium = RenderMedium{ .window = win };

    var tmln = try Timeline.init();

    var _exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    _exit.selfReference();

    std.debug.print("+++ before render", .{});
    try render_model(&arena, on_medium, &_exit, &tmln);
    std.debug.print("+++ after render", .{});

    var exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    exit.selfReference();

    while (exit.toContinue()) {
        const delta_ms = tmln.tickMs();
        exit.collectInput();
        exit.update(delta_ms);

        on_medium.begin();
        defer on_medium.end();
        rl.clearBackground(THEME[0]);
        exit.draw();
    }
}
