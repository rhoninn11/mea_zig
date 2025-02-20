const std = @import("std");
const rl = @import("raylib");
const core = @import("core.zig");

const AppMemory = core.AppMemory;
const RLWindow = core.RLWindow;
const RenderMedium = core.RenderMedium;

const Timeline = @import("../mods/time.zig").Timeline;
const elems = @import("../mods/elements.zig");
const THEME = @import("../mods/core/repr.zig").Theme;

fn render_model() !void {
    const img_size = 1344;
    var on_medium: RenderMedium = RenderMedium{
        .target = rl.RenderTexture2D.init(img_size, img_size),
    };
    defer on_medium.target.unload();
    // const textTo: [1024]u8 = undefined;
    // const textTo1: []u8 = textTo[0..];

    var model = rl.loadModel("assets/hand.glb");
    defer model.unload();

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

    var fmt_memory: [1024]u8 = undefined;
    const fmt_buf = fmt_memory[0..];
    const fname_fmt = "fs/render_viwe_{d}.png";
    {
        on_medium.begin();
        defer on_medium.end();

        // # region update
        rl.updateCamera(&camera, rl.CameraMode.camera_custom);
        // # region render
        rl.beginMode3D(camera);
        defer rl.endMode3D();

        rl.clearBackground(rl.Color.white);

        rl.drawModel(model, center, 1, rl.Color.gray);

        var img = rl.loadImageFromTexture(on_medium.target.texture);
        defer img.unload();
        img.flipVertical();

        const i = 0;
        const fname = try std.fmt.bufPrintZ(fmt_buf, fname_fmt, .{i});
        _ = img.exportToFile(fname);
    }
}
pub fn particles(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    _ = arena;
    // const text_alloc = aloc.gpa;
    var on_medium: RenderMedium = RenderMedium{ .window = win };

    var tmln = try Timeline.basic();

    try render_model();

    var exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    exit.selfReference();

    while (exit.toContinue()) {
        const delta_ms = try tmln.tickMs();
        exit.collectInput();
        exit.update(delta_ms);

        on_medium.begin();
        defer on_medium.end();
        rl.clearBackground(THEME[0]);
        exit.draw();
    }
}
