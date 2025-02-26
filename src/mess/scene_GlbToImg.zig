const std = @import("std");
const rl = @import("raylib");
const core = @import("core.zig");
const log = @import("log.zig");
const utils = @import("utils.zig");

const AppMemory = core.AppMemory;
const RLWindow = core.RLWindow;
const RenderMedium = core.RenderMedium;
const Axis = core.Axis;

const Timeline = @import("../mods/time.zig").Timeline;
const elems = @import("../mods/elements.zig");
const THEME = @import("../mods/core/repr.zig").Theme;

pub var external_glbs: ?[][:0]const u8 = null;

fn render_model() !void {
    const img_size = 1344;
    var on_medium: RenderMedium = RenderMedium{
        .target = rl.RenderTexture2D.init(img_size, img_size),
    };
    defer on_medium.target.unload();
    // const textTo: [1024]u8 = undefined;
    // const textTo1: []u8 = textTo[0..];

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

    // there is critical to control that model dont use fancy compression extensions (like draco)
    // otherwise it cause segmenetaion fault
    const default_models = [_][:0]const u8{
        "assets/hand.glb",
        // "/home/leszek/dev/mea_zig/fs/malpa.glb",
        // "/home/leszek/dev/mea_zig/fs/malpa_off.glb",
    };

    const glbs_to_render = external_glbs orelse default_models[0..];
    for (glbs_to_render, 0..) |glb_file, i| {
        var model = rl.loadModel(glb_file);
        defer model.unload();

        // const a = model.transform;

        const bb = rl.getModelBoundingBox(model);
        const pos = bb.min.negate();
        const model_size = bb.max.subtract(bb.min);
        // const b = model_size.scale(0.5);

        // bbmodel_size.scale(0.5);
        log.logVec3("model size:", model_size);
        log.logVec3("bb min:", bb.min);
        log.logVec3("bb max:", bb.max);

        on_medium.begin();
        defer on_medium.end();

        // # region update
        rl.updateCamera(&camera, rl.CameraMode.camera_custom);
        // # region render
        rl.beginMode3D(camera);
        defer rl.endMode3D();

        rl.clearBackground(rl.Color.beige);

        rl.drawModel(model, pos, 1, rl.Color.gray);

        var img = rl.loadImageFromTexture(on_medium.target.texture);
        defer img.unload();
        img.flipVertical();

        const fname = try std.fmt.bufPrintZ(fmt_buf, fname_fmt, .{i});
        _ = img.exportToFile(fname);
    }
}
pub fn launchAppWindow(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    _ = arena;
    _ = win;
    // const text_alloc = aloc.gpa;
    // var on_medium: RenderMedium = RenderMedium{ .window = win };

    // var tmln = try Timeline.init();

    try render_model();

    // var exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    // exit.selfReference();

    // while (exit.toContinue()) {
    //     const delta_ms = tmln.tickMs();
    //     exit.collectInput();
    //     exit.update(delta_ms);

    //     on_medium.begin();
    //     defer on_medium.end();
    //     rl.clearBackground(THEME[0]);
    //     exit.draw();
    // }
}
