const std = @import("std");
const rl = @import("raylib");
const math = @import("mods/core/math.zig");
const repr = @import("mods/core/repr.zig");
const elems = @import("mods/elements.zig");

const Allocator = std.mem.Allocator;
const Timeline = @import("mods/time.zig").Timeline;

const Vec2i = @import("mods/core/math.zig").Vec2i;
const THEME = @import("mods/circle.zig").THEME;

fn log_slice_info(slice: []f32) void {
    std.debug.print("---\n", .{});
    for (slice) |num_val| {
        std.debug.print(" num value is: {d:.2}\n", .{num_val});
    }
}

const spt = @import("spatial.zig");

const phys = @import("mods/phys.zig");
const Iner = phys.Inertia;
const PhysInprint = phys.PhysInprint;

const ImageBox = @import("ImageBox.zig");
var img_box = ImageBox{};

pub fn springy_osclation() !void {
    var fmt_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const fmt_alloc = fmt_gpa.allocator();
    defer _ = fmt_gpa.deinit();

    var obj_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_arena = std.heap.ArenaAllocator.init(obj_gpa.allocator());
    const arena = obj_arena.allocator();
    defer _ = obj_arena.deinit();

    {
        const info_template = "+++ there is {d} kyes, we need to track for typing\n";
        const info = try std.fmt.allocPrintZ(fmt_alloc, info_template, .{0});
        defer fmt_alloc.free(info);
        std.debug.print("{s}", .{info});
    }
    // img_box.imageLoadTry();
    try simulation(fmt_alloc, arena);
}
const input = @import("mods/input.zig");
const vi2 = math.vi2;

fn simulation(text_alloc: Allocator, arena: Allocator) !void {
    _ = arena;
    const screenWidth = 800;
    const screenHeight = 450;

    const corner = math.vf2{ screenWidth, 0 };

    const tile: [:0]const u8 = "playgroung for image displaying";

    rl.initWindow(screenWidth, screenHeight, tile.ptr);
    defer rl.closeWindow();

    var tmln = try Timeline.basic();
    var life_time_ms: f64 = 0;
    // rl.setTargetFPS(59);

    const n = 5;
    _ = n;
    const action_key = "qwert";
    var skill_keys = input.obtain_keys(action_key.len, action_key);

    var exit = elems.Exiter.spawn(corner, rl.KeyboardKey.key_escape);
    exit.selfReference();

    // TODO: będę tu testował rendering obrazka
    // TODO: może by tak wygenerować algorytmicznie jakąś teksturę, na przykład rysując do niej różne kształy
    while (exit.toContinue()) {
        // exit_key.check_input();
        const delta_ms = try tmln.tickMs();
        life_time_ms += @floatCast(delta_ms);

        const mouse_pose = input.sample_mouse();

        for (&skill_keys) |*skill_key| skill_key.check_input(delta_ms);
        exit.update(delta_ms);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(THEME[0]);

        const info_template: []const u8 = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{delta_ms});
        defer text_alloc.free(info);

        rl.drawText(info, 50, 50, 20, THEME[1]);

        const pointer_pos = rl.Vector3.init(mouse_pose[0], mouse_pose[1], 0);
        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);

        repr.frame(mouse_pose, false);
        exit.draw();
    }
}
