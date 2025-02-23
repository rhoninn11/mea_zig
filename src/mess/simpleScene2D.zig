const std = @import("std");
const rl = @import("raylib");

const repr = @import("../mods/core/repr.zig");
const THEME = repr.Theme;

const elems = @import("../mods/elements.zig");
const input = @import("../mods/input.zig");

const Timeline = @import("../mods/time.zig").Timeline;
const ImageBox = @import("../ImageBox.zig");

const core = @import("core.zig");
const AppMemory = core.AppMemory;
const RLWindow = core.RLWindow;
const RenderMedium = core.RenderMedium;

pub fn launchAppWindow(aloc: *const AppMemory, win: *RLWindow) !void {
    _ = aloc;
    var on_medium: RenderMedium = RenderMedium{ .window = win };

    var tmln = try Timeline.init();
    var life_time_ms: f64 = 0;

    // kb input
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
        const delta_ms = tmln.tickMs();
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
