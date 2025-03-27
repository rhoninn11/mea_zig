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
    const ChessType = chess.ChessRenderState(8, 8);
    render_state: ChessType,
    allocator: Allocator,
    matrices: []rl.Matrix,
    material: rl.Material,
    model: rl.Model,

    pub fn init(alloc: Allocator) !ChessRepr {
        const initor = ChessRepr{
            .render_state = try ChessType.init(alloc),
            .matrices = try alloc.alloc(rl.Matrix, ChessType.fields),
            .allocator = alloc,
            .material = rl.loadMaterialDefault(),
            .model = rl.loadModel("assets/kostka.glb"),
        };
        // hmmm(&initor.material);
        return initor;
    }

    pub fn deinit(self: ChessRepr) void {
        self.render_state.deinit();
        self.allocator.free(self.matrices);
        rl.unloadMaterial(self.material);
        rl.unloadModel(self.model);
    }

    // TODO: precalulate matrices for instanced rendering of fields
    pub fn precalulate(self: *ChessRepr, scale: rl.Vector3) void {
        _ = scale;
        const x_v = self.render_state.x_pos;
        const y_v = self.render_state.y_pos;
        const z_v = self.render_state.z_pos;
        for (x_v, y_v, z_v, 0..) |x, y, z, i| {
            const trans = rl.Matrix.translate(x, y, z);
            self.matrices[i] = trans;
        }
    }

    pub fn repr(self: *ChessRepr) void {
        // i would like to render chessboard with instanced rendering
        const state = self.render_state;
        state.repr();

        // // ---------------------
        // // instancing polygon
        // hmmm(&self.material);
        // rl.drawMeshInstanced(self.model.meshes[0], self.material, self.matrices);
        // // ---------------------

    }
};

fn hmmm(mat: *rl.Material) void {
    const locs = @typeInfo(rl.ShaderLocationIndex).Enum;
    const shader_locs = mat.shader.locs;
    var val: c_int = 0;
    std.debug.print("-----\n", .{});
    inline for (locs.fields) |loc| {
        val = shader_locs[loc.value];
        if (val != -1) {
            std.debug.print("{d} {s} {d}\n", .{ loc.value, loc.name, shader_locs[loc.value] });
        }
    }
    std.debug.print("-----\n", .{});

    const m_size = @sizeOf(rl.Material);
    const s_size = @sizeOf(rl.Shader);
    std.debug.print("!!! m_size {d}, s_size {d}\n", .{ m_size, s_size });

    const shader = mat.shader;
    std.debug.print("!!! shader id {d}\n", .{shader.id});
}

const World = struct {
    observers: [2]math.fvec3,
};

const sphere = @import("sphere.zig");
const math = @import("math.zig");

const ShaderTup = struct {
    vs: [:0]const u8,
    fs: [:0]const u8,
};

fn assetFolder() []const u8 {
    return "assets";
}

fn shaderFiles(name: []const u8) ShaderTup {
    const asset_dir = assetFolder();
    const shader_dir = asset_dir ++ "/shaders/";

    const vert = shader_dir ++ name ++ ".vs";
    const frag = shader_dir ++ name ++ ".fs";

    return ShaderTup{
        .vs = vert,
        .fs = frag,
    };
}

fn paramTest(sh: rl.Shader, param_name: [:0]const u8) void {
    const loc = rl.getShaderLocation(sh, param_name);
    std.debug.print("+++ loc of \"{s}\" is at {d}\n", .{ param_name, loc });
}

fn chessboard_arena(alloc: Allocator, on_medium: RenderMedium, exiter: *Exiter, timeline: *Timeline) !void {
    var p1 = player.Player.init();
    var chess_repr = try ChessRepr.init(alloc);
    defer chess_repr.deinit();

    chess_repr.render_state.debugInfo();

    const text_buffer = try alloc.alloc(u8, 1024);
    defer alloc.free(text_buffer);

    var dynamic = sphere.Sphere{
        .pos = @splat(0),
        .size = 0.1,
    };

    var total_s: f32 = 0;

    const grad = comptime shaderFiles("grad");
    const basic_shader = rl.loadShader(grad.vs, grad.fs);
    defer rl.unloadShader(basic_shader);
    const model_sky = rl.loadModel("assets/globe.glb");
    defer rl.unloadModel(model_sky);
    model_sky.materials[0].shader = basic_shader;

    const matParam = comptime shaderFiles("matParam");
    const exp_shader = rl.loadShader(matParam.vs, matParam.fs);

    paramTest(exp_shader, "center");
    paramTest(exp_shader, "texture0");
    paramTest(exp_shader, "colDiffuse");
    paramTest(exp_shader, "mvp");

    const cube_asset = rl.loadModel("assets/kostka.glb");
    defer rl.unloadModel(cube_asset);
    cube_asset.materials[0].shader = exp_shader;

    // cube_asset.materials[0].

    // const aBitLeft = rl.Vector3.init(0.1, 0, 0);
    while (exiter.toContinue()) {
        const delta_ms = timeline.tickMs();
        exiter.update(delta_ms);
        total_s += delta_ms / 1000;
        p1.update();

        const osc: f32 = std.math.sin(total_s);
        const osc_2: f32 = std.math.cos(total_s * 2);
        const osc_3: f32 = std.math.cos(total_s * 0.5);
        const text = try std.fmt.bufPrintZ(text_buffer, "simple text: {d}", .{osc});

        dynamic.pos[0] = 3 * osc_3;

        const sColor = switch (sphere.sphereTachin(p1.sphere, dynamic)) {
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

            const dyn_pos = math.fvec3Rl(dynamic.pos);
            p1.drawSphere(sColor);
            rl.drawSphere(dyn_pos, dynamic.size, sColor);
            rl.drawModel(model_sky, p1.pos, 15, rl.Color.blue);

            rl.drawModel(cube_asset, rl.Vector3.zero(), 1, rl.Color.white);
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
