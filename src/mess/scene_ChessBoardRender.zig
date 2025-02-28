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
    alloc: *Allocator,
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

    pub fn init(alloc: *Allocator) !Self {
        const xn = 8;
        const yn = xn;
        const fields = 64;
        std.debug.print("+++ how out of memory? {d}\n", .{fields});
        const for_real = try alloc.alloc(f32, 12);
        _ = for_real;

        // std.ArrayListAligned(f32, 4).init(alloc);

        const state = Self{
            .alloc = alloc,
            .x_pos = try alloc.alloc(f32, fields),
            .y_pos = try alloc.alloc(f32, fields),
            .z_pos = try alloc.alloc(f32, fields),
            .col = try alloc.alloc(rl.Color, fields),
        };
        // populate x data
        const x_pos = state.x_pos;
        @memset(x_pos, 3);
        for (0..fields) |x| x_pos[x] = @floatFromInt(x);
        // for (0..xn) |x| x_pos[x] = @floatFromInt(x);
        // const stencil: []f32 = x_pos[0..xn];
        // for (1..yn) |y| {
        //     const x_spot = x_pos[y * xn .. (y + 1) * xn];
        //     @memcpy(stencil, x_spot);
        // }
        // populate y data
        const y_pos = state.y_pos;
        for (0..yn) |y| {
            const y_spot = y_pos[y * yn .. (y + 1) * yn];
            const y_val: f32 = @floatFromInt(y);
            std.debug.print("+++ y val is {d}", .{y_val});
            @memset(y_spot, y_val);
        }
        // populate z data
        @memset(state.z_pos, 0);
        // populate color data
        for (0..fields) |i| {
            state.col[i] = switch (@mod(i, 5)) {
                0 => rl.Color.white,
                1 => rl.Color.black,
                2 => rl.Color.magenta,
                3 => rl.Color.maroon,
                4 => rl.Color.lime,
                else => unreachable,
            };
        }
        return state;
    }

    pub fn repr(self: Self) void {
        for (self.x_pos, self.y_pos, self.z_pos, self.col) |x, z, y, c| {
            const pos = rl.Vector3.init(x, y, z);
            const size = rl.Vector3.init(1, 0.33, 1);
            rl.drawCubeWiresV(pos, size, c);
        }
    }
};

fn render_model(alloc: Allocator, on_medium: RenderMedium, exiter: *Exiter, timeline: *Timeline) !void {
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

    var varAlloc = alloc;
    const for_real = try varAlloc.alloc(f32, 88);
    _ = for_real;
    const chess_state = try ChessRenderState.init(&varAlloc);
    defer chess_state.deinit();

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

            chess_state.repr();
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
