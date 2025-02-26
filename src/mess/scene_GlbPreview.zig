const std = @import("std");
const rl = @import("raylib");
const core = @import("core.zig");
const log = @import("log.zig");
const utils = @import("utils.zig");

const AppMemory = core.AppMemory;
const RLWindow = core.RLWindow;
const RenderMedium = core.RenderMedium;

const Timeline = @import("../mods/time.zig").Timeline;
const elems = @import("../mods/elements.zig");
const Exiter = elems.Exiter;
const THEME = @import("../mods/core/repr.zig").Theme;

fn render_model(alloc: *const std.mem.Allocator, on_medium: RenderMedium, exiter: *Exiter, timeline: *Timeline) !void {
    const up = rl.Vector3.init(0, 1, 0);
    const center = rl.Vector3.init(0, 0, 0);
    const init_pos = rl.Vector3.init(0, 1, -2);
    var camera = rl.Camera{
        .up = up,
        .position = center,
        .target = center,
        .fovy = 60,
        .projection = rl.CameraProjection.camera_perspective,
    };
    camera.target = rl.Vector3.init(0, 0, 0);
    camera.position = init_pos;

    const text_buffer = try alloc.alloc(u8, 1024);
    defer alloc.free(text_buffer);

    const models = [_][:0]const u8{
        // "assets/grid.glb",
        // "assets/hand.glb",
        // "/home/leszek/dev/mea_zig/fs/malpa.glb",
        // "/home/leszek/dev/mea_zig/fs/malpa_off.glb",
        "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_001.glb",
    };

    const space_reference = rl.loadModel("assets/grid.glb");
    defer space_reference.unload();
    const model = rl.loadModel(models[0]);
    defer model.unload();

    const bb = rl.getModelBoundingBox(model);
    log.logVec3("bb min", bb.min);
    log.logVec3("bb max", bb.max);
    const size = bb.max.subtract(bb.min);
    log.logVec3("bb size", size);
    const offset = bb.min.negate();
    log.logVec3("offset", offset);

    var total_s: f32 = 0;
    while (exiter.toContinue()) {
        const delta_ms = timeline.tickMs();
        exiter.update(delta_ms);
        total_s += delta_ms / 1000;

        const osc: f32 = std.math.sin(total_s);
        // const osc_2: f32 = std.math.cos(total_s * 2);
        const text = try std.fmt.bufPrintZ(text_buffer, "simple text: {d}", .{osc});
        // camera.position = init_pos.add(up.scale(osc));
        rl.updateCamera(&camera, rl.CameraMode.camera_free);

        on_medium.begin();
        defer on_medium.end();
        rl.clearBackground(THEME[1]);
        {
            rl.beginMode3D(camera);
            defer rl.endMode3D();
            rl.drawModel(space_reference, center, 1, rl.Color.white);
            // const base_size = 0.5;

            const models_pos = center;
            const scale = 0.02;
            rl.drawModel(model, models_pos, scale, rl.Color.white);

            rl.drawLine3D(rl.Vector3.zero(), bb.min.scale(scale), rl.Color.pink);
            rl.drawLine3D(rl.Vector3.zero(), bb.max.scale(scale), rl.Color.maroon);
            // rl.drawCube(pos, base_size, base_size * 0.33 + osc_2 * 0.1, base_size, rl.Color.white);
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
