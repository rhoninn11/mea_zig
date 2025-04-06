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
const Osc = @import("osc.zig").Osc;

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
        // rlDebugMaterialLocations(&self.material);
        // rl.drawMeshInstanced(self.model.meshes[0], self.material, self.transforms);
        // hmm data addres that goes to c is 32bit, just less sigificatn 32 bits of zig 64bit data address
        // also shader data is messed but it is less problematic thing i guess
        // // ---------------------

    }
};

fn rlDebugMaterialLocations(mat: *rl.Material) void {
    const s_size = @sizeOf(rl.Shader);
    const m_size = @sizeOf(rl.Material);
    const locs = @typeInfo(rl.ShaderLocationIndex).Enum;
    const shader = mat.shader;
    const shader_locs = shader.locs;
    var val: c_int = 0;

    std.debug.print("-----------------------------------------\n", .{});
    defer std.debug.print("-----------------------------------------\n", .{});

    std.debug.print(
        "-- Material struct size {d}\n,--- Shader struct size {d}\n",
        .{ m_size, s_size },
    );
    std.debug.print("-- Shader id {d}\n", .{shader.id});

    inline for (locs.fields) |loc| {
        val = shader_locs[loc.value];
        if (val != -1) {
            std.debug.print("-- {d} {s} {d}\n", .{ loc.value, loc.name, shader_locs[loc.value] });
        }
    }
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

    // defer {
    //     std.debug.print("+++ {s} and {s} loaded\n", .{ vert, frag });
    // }

    return ShaderTup{
        .vs = vert,
        .fs = frag,
    };
}

fn hasUniform(sh: rl.Shader, param_name: [:0]const u8, v: bool) bool {
    const yes = rl.getShaderLocation(sh, param_name) >= 0;
    if (v and !yes) std.debug.print("+++ {s} is missing\n", .{param_name});
    return yes;
}

fn hasUniforms(sh: rl.Shader, names: []const [:0]const u8, v: bool) bool {
    var ans = true;
    for (names) |name|
        ans = ans and hasUniform(sh, name, v);
    return ans;
}

inline fn rlTranslate(v: math.fvec3) rl.Matrix {
    return rl.Matrix.translate(v[0], v[1], v[2]);
}

fn axisSlide(axis: math.fvec3, amount: f32) rl.Matrix {
    const amountV: math.fvec3 = @splat(amount);
    return rlTranslate(axis * amountV);
}

fn bypassAssert(cond: bool, comptime bypas: bool) void {
    if (!bypas) {
        std.debug.assert(cond);
    }
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
    const shader_gradient = rl.loadShader(
        grad.vs,
        grad.fs,
    );
    defer rl.unloadShader(shader_gradient);
    const model_sky = rl.loadModel("assets/globe.glb");
    defer rl.unloadModel(model_sky);
    model_sky.materials[0].shader = shader_gradient;

    const param = comptime shaderFiles("param");
    const shader_parametric = rl.loadShader(
        param.vs,
        param.fs,
    );
    defer rl.unloadShader(shader_parametric);
    const model_cube = rl.loadModel("assets/kostka.glb");
    defer rl.unloadModel(model_cube);
    model_cube.materials[1].shader = shader_parametric;
    // hmmm: why this model uses mateial at index 1?

    const locs_to_find: []const [:0]const u8 = &.{
        "mvp",
        "texture0",
        "colDiffuse",
        "user_color",
        "user_mat",
    };
    const has_all = hasUniforms(shader_parametric, locs_to_find, true);
    bypassAssert(has_all, false);

    const user_mat_loc = rl.getShaderLocation(shader_parametric, "user_mat");
    const user_color = rl.getShaderLocation(shader_parametric, "user_color");
    const red: @Vector(4, f32) = .{ 1, 0, 0, 0 };
    const mat_iden = rl.Matrix.identity();

    const sh_axis: @Vector(3, f32) = .{ 1, 0, 0 };
    var sh_mat = axisSlide(sh_axis, 1);
    // transform = rl.Matrix.identity();
    // transform = transform.multiply(rl.Matrix.scale(0.5, 0.5, 0.5));

    rl.setShaderValue(shader_parametric, user_color, &red, .shader_uniform_vec4);
    rl.setShaderValueMatrix(shader_parametric, user_mat_loc, mat_iden);

    std.debug.print("hhh {d}\n", .{model_cube.materialCount});

    // cube_asset.materials[0].

    var osc_basic = Osc{ .freq = 0.25 };
    var osc_duo = Osc{ .freq = 1 };
    var osc_trio = Osc{ .freq = 4 };
    const osc_slice: []const *Osc = &.{ &osc_basic, &osc_duo, &osc_trio };

    while (exiter.toContinue()) {
        p1.update();

        const delta_ms = timeline.tickMs();
        exiter.update(delta_ms);
        for (osc_slice) |osc| osc.update(delta_ms);
        total_s += delta_ms / 1000;

        const axis_pos = osc_slice[0].sample();
        dynamic.pos[0] = 3 * axis_pos;
        const text_value = axis_pos;
        const text = try std.fmt.bufPrintZ(text_buffer, "simple text: {d}", .{text_value});

        sh_mat = axisSlide(sh_axis, osc_slice[0].sample());
        rl.setShaderValueMatrix(shader_parametric, user_mat_loc, sh_mat);

        const sColor = switch (sphere.sphereTachin(p1.colider, dynamic)) {
            .far => rl.Color.orange,
            .touching => rl.Color.purple,
            else => rl.Color.pink,
        };

        on_medium.begin();
        defer {
            // while in default 3D "layer" draw rest of ui
            rl.drawText(text.ptr, 10, 10, 24, THEME[1]);
            exiter.draw();
            on_medium.end();
        }

        rl.clearBackground(THEME[1]);
        {
            rl.beginMode3D(p1.camera);
            defer rl.endMode3D();
            const base_size = 0.5;
            const osc_val = osc_slice[1].sample();
            const osc_val2 = osc_slice[2].sample();
            const pos = rl.Vector3.init(0, osc_val * 0.33, 0);
            rl.drawCube(pos, base_size, base_size * 0.33 + osc_val * 0.1, base_size, rl.Color.white);
            const pos_2 = pos.add(rl.Vector3.init(1, 0, 0));
            rl.drawCube(pos_2, base_size, base_size * 0.33 + osc_val2 * 0.1, base_size, rl.Color.black);

            chess_repr.repr();

            const dyn_pos = math.fvec3Rl(dynamic.pos);
            p1.drawSphere(sColor);
            rl.drawSphere(dyn_pos, dynamic.size, sColor);
            rl.drawModel(model_sky, p1.pos, 100, rl.Color.blue);

            rl.drawModel(model_cube, rl.Vector3.zero(), 1, rl.Color.blue);
        }
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
