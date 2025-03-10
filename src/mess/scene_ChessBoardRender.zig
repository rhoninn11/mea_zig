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
const player = @import("player.zig");

const Allocator = std.mem.Allocator;
const chess = @import("chess.zig");

const ChessRepr = struct {
    render_state: chess.ChessRenderState,
    allocator: Allocator,
    // cube_mesh: rl.Mesh,

    pub fn init(alloc: Allocator) !ChessRepr {
        return ChessRepr{
            .render_state = try chess.ChessRenderState.init(alloc),
            .allocator = alloc,
            // .cube_mesh = rl.genMeshCube(1, 1, 1),
        };
    }

    pub fn deinit(self: ChessRepr) void {
        self.render_state.deinit();
    }

    pub fn repr(self: *ChessRepr) void {
        const state = self.render_state;
        state.repr();
    }
};

const World = struct {
    observers: [2]math.fvec3,
};

const sphere = @import("sphere.zig");
const math = @import("math.zig");

fn chessboard_arena(alloc: Allocator, on_medium: RenderMedium, exiter: *Exiter, timeline: *Timeline) !void {
    var p1 = player.Player.init();
    var chess_repr = try ChessRepr.init(alloc);
    defer chess_repr.deinit();

    chess_repr.render_state.debugInfo();

    const text_buffer = try alloc.alloc(u8, 1024);
    defer alloc.free(text_buffer);

    var main = sphere.Sphere{
        .pos = @splat(0),
        .size = 0.3,
    };
    var dynamic = sphere.Sphere{
        .pos = @splat(0),
        .size = 0.1,
    };

    var total_s: f32 = 0;
    const model_sky = rl.loadModel("assets/globe.glb");
    defer rl.unloadModel(model_sky);
    const basic_shader = rl.loadShader("assets/base.vs", "assets/simple.fs");
    defer rl.unloadShader(basic_shader);

    model_sky.materials[0].shader = basic_shader;
    const skysphere = &model_sky.meshes[0];
    const vert_num: u32 = @intCast(skysphere.vertexCount);

    std.debug.print("+++ vert count is: {d}\n", .{vert_num});
    // const aBitLeft = rl.Vector3.init(0.1, 0, 0);
    while (exiter.toContinue()) {
        const delta_ms = timeline.tickMs();
        exiter.update(delta_ms);
        total_s += delta_ms / 1000;
        p1.update();

        const p_pos = p1.camera.target;
        main.pos = math.asRelVec3(p_pos);

        const osc: f32 = std.math.sin(total_s);
        const osc_2: f32 = std.math.cos(total_s * 2);
        const osc_3: f32 = std.math.cos(total_s * 0.5);
        const text = try std.fmt.bufPrintZ(text_buffer, "simple text: {d}", .{osc});

        dynamic.pos[0] = 3 * osc_3;

        const sColor = switch (sphere.tachin(main, dynamic)) {
            .far => rl.Color.orange,
            .touching => rl.Color.purple,
            else => rl.Color.pink,
        };

        on_medium.begin();
        defer on_medium.end();
        rl.clearBackground(THEME[1]);
        {
            rl.beginMode3D(p1.camera);
            defer rl.endMode3D();
            const base_size = 0.5;
            const pos = rl.Vector3.init(0, osc * 0.33, 0);
            rl.drawCube(pos, base_size, base_size * 0.33 + osc_2 * 0.1, base_size, rl.Color.white);
            const pos_2 = pos.add(rl.Vector3.init(1, 0, 0));
            rl.drawCube(pos_2, base_size, base_size * 0.33 + osc_2 * 0.1, base_size, rl.Color.black);

            chess_repr.repr();

            const obs_pos = math.fvec3Rl(main.pos);
            rl.drawSphere(obs_pos, main.size, sColor);
            rl.drawSphere(dynamic.rlPos(), dynamic.size, sColor);
            rl.drawModel(model_sky, p_pos, 15, rl.Color.blue);
        }

        rl.drawText(text.ptr, 10, 10, 24, THEME[0]);
        exiter.draw();
    }
}
pub fn launchAppWindow(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    // const text_alloc = aloc.gpa;
    const on_medium: RenderMedium = RenderMedium{ .rlwin = win };

    var tmln = try Timeline.init();

    var _exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    _exit.selfReference();

    try chessboard_arena(arena, on_medium, &_exit, &tmln);
}
