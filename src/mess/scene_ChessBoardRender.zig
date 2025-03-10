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

const Allocator = std.mem.Allocator;

const ChessRenderState = struct {
    const Self = @This();
    alloc: Allocator,
    x_pos: []f32,
    y_pos: []f32,
    z_pos: []f32,
    col: []rl.Color,

    pub fn deinit(self: Self) void {
        self.alloc.free(self.x_pos);
        self.alloc.free(self.y_pos);
        self.alloc.free(self.z_pos);
        self.alloc.free(self.col);
    }

    fn initPos(self: *Self, sz: anytype) void {
        const x_pos = self.x_pos;
        @memset(x_pos, 3);
        for (0..sz.fields) |x| x_pos[x] = @floatFromInt(@mod(x, 8));

        const y_pos = self.y_pos;
        for (0..sz.yn) |y| {
            const row_idx = y * sz.yn;
            const row_value: f32 = @floatFromInt(y);
            const row_memory = y_pos[row_idx .. row_idx + sz.xn];
            @memset(row_memory, row_value);
        }
        @memset(self.z_pos, 0);

        math.center(self.x_pos);
        math.center(self.y_pos);
    }

    pub fn init(alloc: Allocator) !Self {
        const xn = 8;
        const yn = xn;
        const fields = 64;

        var state = Self{
            .alloc = alloc,
            .x_pos = try alloc.alloc(f32, fields),
            .y_pos = try alloc.alloc(f32, fields),
            .z_pos = try alloc.alloc(f32, fields),
            .col = try alloc.alloc(rl.Color, fields),
        };

        state.initPos(.{
            .fields = fields,
            .xn = xn,
            .yn = yn,
        });

        for (0..fields) |i| {
            const row_flip = @mod(@divTrunc(i, 8), 2);
            state.col[i] = switch (@mod(i + row_flip, 2)) {
                inline 0 => rl.Color.white,
                inline 1 => rl.Color.black,
                else => unreachable,
            };
        }
        return state;
    }

    pub fn repr(self: Self) void {
        for (self.x_pos, self.y_pos, self.z_pos, self.col) |x, z, y, c| {
            var pos = rl.Vector3.init(x, y, z);
            pos = pos.multiply(rl.Vector3.init(8, 8, 8));
            const size = rl.Vector3.init(1, 0.33, 1);
            rl.drawCubeWiresV(pos, size, c);
        }
    }

    pub fn debugInfo(self: *Self) void {
        const x_mm = math.minMax(self.x_pos);
        const y_mm = math.minMax(self.y_pos);
        const z_mm = math.minMax(self.z_pos);
        std.debug.print("+++ X {d} {d}\n", .{ x_mm[0], x_mm[1] });
        std.debug.print("+++ Y {d} {d}\n", .{ y_mm[0], y_mm[1] });
        std.debug.print("+++ Z {d} {d}\n", .{ z_mm[0], z_mm[1] });
    }
};

const ChessRepr = struct {
    render_state: ChessRenderState,
    allocator: Allocator,
    // cube_mesh: rl.Mesh,

    pub fn init(alloc: Allocator) !ChessRepr {
        return ChessRepr{
            .render_state = try ChessRenderState.init(alloc),
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
const view = @import("view.zig");

fn render_model(alloc: Allocator, on_medium: RenderMedium, exiter: *Exiter, timeline: *Timeline) !void {
    var camera = view.cameraPersp();
    camera.target = rl.Vector3.init(0, 0, 0);
    // view = camera.getMatrix();
    const camera_pos = rl.Vector3.init(0, 1, -2);
    camera.position = camera_pos;

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

        rl.updateCamera(&camera, rl.CameraMode.camera_third_person);

        main.pos = math.asRelVec3(camera.target);

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
            rl.beginMode3D(camera);
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
            rl.drawModel(model_sky, camera.target, 15, rl.Color.blue);
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

    try render_model(arena, on_medium, &_exit, &tmln);
}
