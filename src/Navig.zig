const std = @import("std");
const rl = @import("raylib");
const math = @import("mods/core/math.zig");
const repr = @import("mods/core/repr.zig");
const elems = @import("mods/elements.zig");

const Allocator = std.mem.Allocator;
const Timeline = @import("mods/time.zig").Timeline;

const THEME = @import("mods/core/repr.zig").Theme;

const spt = @import("spatial.zig");

const ImageBox = @import("ImageBox.zig");

const input = @import("mods/input.zig");
const vi2 = math.iv2;
const vf2 = math.fv2;

const AppMemory = @import("mess/core.zig").AppMemory;

pub const RLWindow = struct {
    corner: vf2,
    size: vf2,
};

const RenderMedium = union(enum) {
    window: *RLWindow,
    target: rl.RenderTexture,

    pub fn begin(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.beginDrawing(),
            RenderMedium.target => |rtxt| rl.beginTextureMode(rtxt),
        }
    }

    pub fn end(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.endDrawing(),
            RenderMedium.target => rl.endTextureMode(),
        }
    }
};

pub fn particles(aloc: *const AppMemory, win: *RLWindow) !void {
    _ = aloc;
    var on_medium: RenderMedium = RenderMedium{ .window = win };

    var tmln = try Timeline.basic();
    var life_time_ms: f64 = 0;

    // kb input
    const n = 5;
    _ = n;
    const action_key = "qwert";
    var skill_keys = input.obtain_keys(action_key.len, action_key);

    // elements
    var exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    exit.selfReference();

    const dot_number: u32 = 256;

    var simple_benchmark = elems.SurfaceInfo(dot_number){ .tiles = undefined };
    simple_benchmark.benchGrid(win.size);

    var imgB = ImageBox{};
    imgB.imageLoadTry();

    var fmt_memory: [1024]u8 = undefined;
    const fmt_buf = fmt_memory[0..];
    // TODO: będę tu testował rendering obrazka
    // na przykład tworząc prosty system cząstekowy
    // gdzie particle sobie oscylują w różnych miejscach
    // to mógłby byś w pewnym sensie pewien benchmark wydajności
    while (exit.toContinue()) {
        // exit_key.check_input();
        const delta_ms = try tmln.tickMs();
        const fps = 1000 / delta_ms;
        life_time_ms += @floatCast(delta_ms);

        const mouse_pose = input.sample_mouse();

        for (&skill_keys) |*skill_key| skill_key.collectiInput();
        exit.collectInput();
        const pointer_pos = rl.Vector3.init(mouse_pose[0], mouse_pose[1], 0);

        // for(& skill_keys) | *|
        exit.update(delta_ms);

        const info_tmpl: []const u8 = "Congrats! You created your first window!\n Frame time {d:.3}ms\n fps {d}\n";
        const info_text = try std.fmt.bufPrintZ(fmt_buf, info_tmpl, .{ delta_ms, fps });
        // defer text_alloc.free(info);

        on_medium.begin();
        defer on_medium.end();

        rl.clearBackground(THEME[0]);
        exit.draw();
        simple_benchmark.draw();

        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);

        repr.frame(mouse_pose, false);
        rl.drawText(info_text, 50, 50, 20, THEME[1]);
        imgB.repr();
    }
}
