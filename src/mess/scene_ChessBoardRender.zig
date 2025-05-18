const std = @import("std");
const rl = @import("raylib");
const core = @import("core.zig");
const dbg = @import("debug.zig");
const AppMemory = core.AppMemory;
const RLWindow = core.RLWindow;
const RenderMedium = core.RenderMedium;

const Timeline = @import("../mods/time.zig").Timeline;
const elems = @import("../mods/elements.zig");
const Exiter = elems.Exiter;
const THEME = @import("repr.zig").theme;
const player = @import("player.zig");
const sound = @import("sound.zig");

const Allocator = std.mem.Allocator;
const chess = @import("boards.zig");
const Osc = @import("osc.zig").Osc;

// // ---------------------
// // instancing experiment
// dgb.rlDebugMaterialLocations(&self.material);
// const iden_v: []const rl.Matrix = &.{rl.Matrix.identity()};  z
// std.debug.print("+++ {d}\n", .{self.model.materialCount});
// rl.drawMeshInstanced(self.model.meshes[1], self.material, iden_v);
//
// Now it not crashes, but rendering is broken is broken
// maybe i can be excuse to use renderDoc?
// But either way i should create new object to experiment with instancing
// // ---------------------

const World = struct {
    observers: [2]math.fvec3,
};

const sphere = @import("sphere.zig");
const math = @import("math.zig");
const sh = @import("shaders.zig");

inline fn rlTranslate(v: math.fvec3) rl.Matrix {
    return rl.Matrix.translate(v[0], v[1], v[2]);
}

fn slideOnAxis(axis: math.fvec3, amount: f32) rl.Matrix {
    const amountV: math.fvec3 = @splat(amount);
    return rlTranslate(axis * amountV);
}

// TODO: for now as tile distance get farther, lack of camera following is oviously noticible,
// would be nice to fix it:D
fn chessboard_arena(alloc: Allocator, medium: RenderMedium, exiter: *Exiter, timeline: *Timeline) !void {
    _ = sound.getBam();
    // player
    var world = try chess.WorldNavigBoard().init(alloc);
    defer world.deinit();

    var p1 = player.Player.init();
    p1.addToTheWorld(&world);

    const cube_mesh = rl.genMeshCube(0.5, 0.5, 0.5);
    const cube_model = try rl.loadModelFromMesh(cube_mesh);
    defer rl.unloadModel(cube_model);
    const cube_material = rl.loadMaterialDefault() catch unreachable;
    defer rl.unloadMaterial(cube_material);

    const fonts = @import("fonts.zig");
    const font = fonts.getFont();
    defer rl.unloadFont(font);
    fonts.inspectFont(&font);

    var chessboard = world.board;
    chessboard.board.mesh = cube_mesh;
    chessboard.board.material = cube_material;
    chessboard.board.board.debugInfo();

    chessboard.oscInfo();
    chessboard.update(500);
    chessboard.oscInfo();

    const text_buffer = try alloc.alloc(u8, 1024);
    defer alloc.free(text_buffer);

    var dynamic = sphere.Sphere{
        .pos = @splat(0),
        .size = 0.1,
    };

    var total_s: f32 = 0;

    // raylib
    const grad = comptime sh.shaderFiles("grad");
    const shader_gradient = try rl.loadShader(
        grad.vs,
        grad.fs,
    );
    defer rl.unloadShader(shader_gradient);
    const model_sky = try rl.loadModel("assets/globe.glb");
    defer rl.unloadModel(model_sky);
    model_sky.materials[0].shader = shader_gradient;

    const parametric = try sh.Paramatric.init(.knot);
    defer parametric.deinit();

    var cube_param = try sh.Paramatric.init(.cube);
    defer cube_param.deinit();

    const trans = rl.Matrix.translate(0, -1.2, 0);
    const base = 8.81;
    const scale = rl.Matrix.scale(base, 1, base);

    // why color depends on transform...
    cube_param.setTransform(scale.multiply(trans));

    const maroon = rl.Color.red;
    cube_param.setColor(&maroon);

    // loc names could be accesed from Parametric i guess, it would be so nice
    // i could generate enum to select location by name, but has guarantee that
    // is written corectly
    const user_mat_loc = rl.getShaderLocation(parametric.shader, "user_mat");
    const user_color = rl.getShaderLocation(parametric.shader, "user_color");
    const red: @Vector(4, f32) = .{ 1, 0, 0, 0 };
    const mat_iden = rl.Matrix.identity();

    const sh_axis: @Vector(3, f32) = .{ 0, 1, 0 };
    var t_on_axis = slideOnAxis(sh_axis, 1);

    rl.setShaderValue(parametric.shader, user_color, &red, .vec4);
    rl.setShaderValueMatrix(parametric.shader, user_mat_loc, mat_iden);

    var osc_basic = Osc{ .freq = 0.25 };
    var osc_duo = Osc{ .freq = 0.5 };
    var osc_trio = Osc{ .freq = 0.75 };
    const osc_slice: []const *Osc = &.{ &osc_basic, &osc_duo, &osc_trio };

    // editor
    const E = player.EditorMemory;
    var hmm: [@sizeOf(E.Tpy) * E.Slots]E.Tpy = undefined;
    var editor = player.EditorMemory{
        .placedObjects = hmm[0..],
        .slot = 0,
    };
    editor.load();
    defer editor.save() catch {
        std.log.err("failed to save\n", .{});
    };
    // ---

    const d_text = @import("dubble.zig").default.text;
    const zero = rl.Vector3.zero();
    while (exiter.toContinue()) {
        var buf_len: u16 = 0;
        @memset(text_buffer, 0);

        const delta_ms = timeline.tickMs();
        p1.update(delta_ms);
        exiter.update(delta_ms);
        // chessboard.update(delta_ms);
        for (osc_slice) |osc| osc.update(delta_ms);
        total_s += delta_ms / 1000;

        const axis_pos = osc_slice[0].sample();
        dynamic.pos[0] = 3 * axis_pos;
        const text_value = axis_pos;
        const text = try std.fmt.bufPrintZ(text_buffer, "simple text: {d}", .{text_value});
        buf_len += @intCast(text.len);
        buf_len += 1;

        const o = p1.pos_physout;
        const debug_text = try std.fmt.bufPrintZ(text_buffer[buf_len..], " x: {d:.2}\n y: {d:.2}\n z: {d:.2}", .{ o.x, o.y, o.z });

        t_on_axis = slideOnAxis(sh_axis, osc_slice[0].sample());
        t_on_axis = t_on_axis.multiply(rl.Matrix.translate(0, 0, -4));
        rl.setShaderValueMatrix(parametric.shader, user_mat_loc, t_on_axis);

        const sColor = switch (sphere.sphereTachin(p1.colider, dynamic)) {
            .miss => rl.Color.orange,
            .touching => rl.Color.purple,
        };

        // it starts 2D context,
        medium.begin();
        rl.clearBackground(THEME[1]);
        defer {
            // draw ui at the end
            d_text.repr(text, .{ 10, 10 }, 24, THEME);
            rl.drawText(text, 10, 10, 24, THEME[1]);
            d_text.repr(debug_text, .{ 10, 44 }, 24, THEME);

            //unicode tester
            d_text.repr(fonts.test_string, .{ 10, 160 }, 34, THEME);

            exiter.draw();
            if (p1.operation_mode == .edit) {
                p1.ui.repr(&p1);
            }
            medium.end();
        }

        // drawing 3d
        rl.beginMode3D(p1.camera);
        {
            defer rl.endMode3D();
            const base_size = 0.5;
            const osc_val = osc_slice[1].sample();
            const osc_val2 = osc_slice[2].sample();
            const pos = rl.Vector3.init(0, osc_val * 0.33, 4);
            rl.drawCube(pos, base_size, base_size * 0.33 + osc_val * 0.1, base_size, rl.Color.white);
            const pos_2 = pos.add(rl.Vector3.init(1, 0, 0));
            rl.drawCube(pos_2, base_size, base_size * 0.33 + osc_val2 * 0.1, base_size, rl.Color.black);

            const dyn_pos = math.asRlvec3(dynamic.pos);
            p1.repr(sColor);
            rl.drawSphere(dyn_pos, dynamic.size, sColor);
            rl.drawModel(model_sky, p1.pos, 100, rl.Color.blue);

            parametric.repr(zero);
            // chessboard.board.repr();
            world.repr();

            for (0..p1.spot_num) |i| {
                const redner_spot = p1.spots[i];
                rl.drawModel(cube_model, redner_spot, 0.5, rl.Color.purple);
            }
            // cube_param.repr(zero);

            // rl.drawMes
        }
    }
}
pub fn launchAppWindow(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    const medium: RenderMedium = RenderMedium{ .rlwin = win };

    var timeline = try Timeline.init();
    var _exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.escape);
    _exit.selfReference();

    try chessboard_arena(
        arena,
        medium,
        &_exit,
        &timeline,
    );
}
