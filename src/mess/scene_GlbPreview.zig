const std = @import("std");
const rl = @import("raylib");
const core = @import("core.zig");
const utils = @import("utils.zig");
const view = @import("view.zig");

const Allocator = std.mem.Allocator;

const AppMemory = core.AppMemory;
const RLWindow = core.RLWindow;
const RenderMedium = core.RenderMedium;

const Timeline = @import("../mods/time.zig").Timeline;
const elems = @import("../mods/elements.zig");
const Exiter = elems.Exiter;
const THEME = @import("../mods/core/repr.zig").Theme;

fn endLine() void {
    std.debug.print("\n", .{});
}

fn modelDebugInfo(model: *rl.Model) void {
    const mat_num: u32 = @intCast(model.materialCount);
    const mesh_num: u32 = @intCast(model.meshCount);
    std.debug.print("+++ info about mesh:\n\tmaterials - {d}\n\tmeshes - {d}\n\n", .{ mat_num, mesh_num });

    std.debug.print("meshes: ", .{});
    for (0..mesh_num) |i| std.debug.print("{d} ", .{i});
    endLine();
    std.debug.print("mats: ", .{});
    for (0..mat_num) |i| std.debug.print("{d} ", .{i});
    endLine();

    for (0..mesh_num) |i| {
        const mesh = model.meshes[i];
        std.debug.print("mesh({d}) has {d} verts\n", .{ i, mesh.vertexCount });
    }
}

fn render_model(alloc: Allocator, rlwin: *RLWindow, exiter: *Exiter, timeline: *Timeline) !void {
    const center = rl.Vector3.init(0, 0, 0);
    var camera = view.cameraPersp();
    // camera.target = center;
    // camera.position = rl.Vector3.init(0, 1, 0);

    const main = RenderMedium{ .rlwin = rlwin };
    const tex_size = 256;
    const preview = RenderMedium{
        .rltex = rl.loadRenderTexture(tex_size, tex_size),
    };
    const preview_points = RenderMedium{
        .rltex = rl.loadRenderTexture(tex_size, tex_size),
    };
    defer rl.unloadRenderTexture(preview.rltex);
    defer rl.unloadRenderTexture(preview_points.rltex);

    const text_buffer = try alloc.alloc(u8, 1024);
    defer alloc.free(text_buffer);

    const glbs = [_][:0]const u8{
        "assets/hand.glb",
        "/home/leszek/dev/mea_dev/sub/mea_zig/fs/elephant.glb", //68Mvert? nah
        // "assets/grid.glb",
        // "/home/leszek/dev/mea_zig/fs/malpa.glb",
        // "/home/leszek/dev/mea_zig/fs/malpa_off.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_001.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_002.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_003.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_004.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_005.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_006.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_007.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_008.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/model_009.glb",
        // "/home/leszek/dev/mea_zig/fs/glbs/tride/models/untitled.glb",
    };

    const space_reference = rl.loadModel("assets/grid.glb");
    defer space_reference.unload();

    var modelsV: [glbs.len]rl.Model = undefined;
    var scaleV: [glbs.len]f32 = undefined;
    var cOffsetV: [glbs.len]rl.Vector3 = undefined;
    var sizeV: [glbs.len]rl.Vector3 = undefined;
    for (glbs, 0..) |glb_file, i| {
        const model = rl.loadModel(glb_file);
        const bb = rl.getModelBoundingBox(model);
        const size = bb.max.subtract(bb.min);
        const offset = bb.min.add(size.scale(0.5)).negate();
        const scale = 1 / utils.maxAxis(size);

        modelsV[i] = model;
        sizeV[i] = size.scale(scale);
        cOffsetV[i] = offset.scale(scale);
        scaleV[i] = scale;
    }
    defer for (&modelsV) |*model| model.unload();

    for (&modelsV) |*model| modelDebugInfo(model);

    const sinLut = circleLut(glbs.len, 1);

    var total_s: f32 = 0;
    var to_run = true;
    const leave_after_s = 100;
    while (exiter.toContinue() and to_run) {
        const delta_ms = timeline.tickMs();
        exiter.update(delta_ms);
        total_s += delta_ms / 1000;
        if (total_s > leave_after_s) {
            to_run = false;
        }

        const osc: f32 = std.math.sin(total_s);
        // const osc_2: f32 = std.math.cos(total_s * 2);
        const text = try std.fmt.bufPrintZ(text_buffer, "simple text: {d}", .{osc});
        // camera.position = init_pos.add(up.scale(osc));
        rl.updateCamera(&camera, rl.CameraMode.camera_free);

        {
            preview.begin();
            defer preview.end();
            rl.beginMode3D(camera);
            defer rl.endMode3D();
            rl.clearBackground(rl.Color.black);
            for (modelsV, cOffsetV, scaleV, sinLut) |m, cO, s, sl| {
                const pos = cO.add(sl);
                rl.drawModelWires(m, pos, s, rl.Color.red);
            }
        }
        {
            preview_points.begin();
            defer preview_points.end();
            rl.beginMode3D(camera);
            defer rl.endMode3D();
            rl.clearBackground(rl.Color.black);
            for (modelsV, cOffsetV, scaleV, sinLut) |m, cO, s, sl| {
                const pos = cO.add(sl);
                rl.drawModelPoints(m, pos, s, rl.Color.lime);
            }
        }

        main.begin();
        defer main.end();
        rl.clearBackground(THEME[1]);
        {
            rl.beginMode3D(camera);
            defer rl.endMode3D();
            rl.drawModel(space_reference, center.add(rl.Vector3.init(0, -1, 0)), 1, rl.Color.white);
            // const base_size = 0.5;
            for (modelsV, cOffsetV, scaleV, sinLut) |m, cO, s, sl| {
                const pos = cO.add(sl);
                rl.drawModel(m, pos, s, rl.Color.white);
            }

            // rl.drawLine3D(rl.Vector3.zero(), cOffsetV[0], rl.Color.red);
            // rl.drawLine3D(cOffsetV[0], cOffsetV[0].add(sizeV[0]), rl.Color.blue);
            // rl.drawLine3D(origin, mSize.scale(scale).add(origin), rl.Color.blue);
            // rl.drawCube(pos, base_size, base_size * 0.33 + osc_2 * 0.1, base_size, rl.Color.white);
        }

        rl.drawText(text.ptr, 10, 10, 24, THEME[0]);
        const x_pos = rlwin.size[0] - tex_size;
        rl.drawTextureEx(preview.rltex.texture, rl.Vector2.init(x_pos, 0 * tex_size), 0, 1, rl.Color.white);
        rl.drawTextureEx(preview_points.rltex.texture, rl.Vector2.init(x_pos, 1 * tex_size), 0, 1, rl.Color.white);

        exiter.draw();
    }

    const image = rl.loadImageFromTexture(preview.rltex.texture);
    defer image.unload();

    _ = rl.exportImage(image, "fs/headles.png");
}

const spatial = @import("../spatial.zig");

fn circleLut(comptime len: u32, size: f32) [len]rl.Vector3 {
    const progress = spatial.LinStage(len, .NoLast);
    const circle_size = 5;
    var lut: [len]rl.Vector3 = undefined;

    for (progress, 0..) |val, i| {
        const x = std.math.cos(val * std.math.pi * 2) * circle_size;
        const y = std.math.sin(val * std.math.pi * 2) * circle_size;
        lut[i] = rl.Vector3.init(x, 0, y).scale(size);
    }
    return lut;
}

pub fn launchAppWindow(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    // const text_alloc = aloc.gpa;

    var tmln = try Timeline.init();

    var _exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    _exit.selfReference();

    try render_model(arena, win, &_exit, &tmln);
}
