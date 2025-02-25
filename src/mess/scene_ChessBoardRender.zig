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
    camera.target = rl.Vector3.init(0, 0, 0);
    // view = camera.getMatrix();
    const camera_pos = rl.Vector3.init(0, 1, -2);
    camera.position = camera_pos;

    const xy = 8;
    const grid_x: []f32 = try alloc.alloc(f32, xy * xy);
    defer alloc.free(grid_x);
    for (0..xy) |x| grid_x[x] = @floatFromInt(x);
    for (1..xy) |y| @memcpy(grid_x[0..xy], grid_x[xy * y .. xy * (y + 1)]);

    const grid_y: []f32 = try alloc.alloc(f32, xy * xy);
    defer alloc.free(grid_y);
    for (0..xy) |y| @memset(grid_y[y * xy .. (y + 1) * xy], @floatFromInt(y));

    // color also should be precalculated
    const grid_color: []bool = try alloc.alloc(bool, xy * xy);
    defer alloc.free(grid_color);

    const text_buffer = try alloc.alloc(u8, 1024);
    defer alloc.free(text_buffer);

    var total_s: f32 = 0;
    while (exiter.toContinue()) {
        const delta_ms = timeline.tickMs();
        exiter.update(delta_ms);
        total_s += delta_ms / 1000;

        rl.updateCamera(&camera, rl.CameraMode.camera_custom);

        const osc: f32 = std.math.sin(total_s);
        const osc_2: f32 = std.math.cos(total_s * 2);
        const text = try std.fmt.bufPrintZ(text_buffer, "simple text: {d}", .{osc});

        on_medium.begin();
        defer on_medium.end();
        rl.clearBackground(THEME[1]);
        {
            rl.beginMode3D(camera);
            defer rl.endMode3D();
            const base_size = 0.5;
            const pos = rl.Vector3.init(0, osc * 0.33, 0);
            rl.drawCube(pos, base_size, base_size * 0.33 + osc_2 * 0.1, base_size, rl.Color.white);
            const pos_2 = pos.add(rl.Vector3.init(1, 0, 0));
            rl.drawCube(pos_2, base_size, base_size * 0.33 + osc_2 * 0.1, base_size, rl.Color.black);

            for (grid_x, grid_y) |x, y| {
                const grid_pos = rl.Vector3.init(x, 0, y);
                _ = grid_pos;
            }
        }

        rl.drawText(text.ptr, 10, 10, 24, THEME[0]);
        exiter.draw();
    }
}
pub fn launchAppWindow(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    // const text_alloc = aloc.gpa;
    const on_medium: RenderMedium = RenderMedium{ .window = win };

    var tmln = try Timeline.init();

    var _exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    _exit.selfReference();

    try render_model(&arena, on_medium, &_exit, &tmln);
}
