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

const Memalo = struct {
    text: Allocator,
    arean: Allocator,
};

pub fn springy_osclation() !void {
    var fmt_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_arena = std.heap.ArenaAllocator.init(obj_gpa.allocator());
    defer {
        _ = obj_arena.deinit();
        _ = obj_gpa.deinit();
    }

    const mm = Memalo{
        .text = fmt_gpa.allocator(),
        .arean = obj_arena.allocator(),
    };

    try simulation(&mm);
}
const input = @import("mods/input.zig");
const vi2 = math.vi2;
const vf2 = math.vf2;

fn SurfaceInfo(n: u32) type {
    return struct { tiles: [n]repr.Tile };
}

fn simulation(aloc: *const Memalo) !void {
    const arena = aloc.arean;
    _ = arena;
    const text_alloc = aloc.text;

    const screenWidth = 1600;
    const screenHeight = 900;

    const corner = math.vf2{ screenWidth, 0 };

    const title: [:0]const u8 = "playgroung for image displaying";

    rl.initWindow(screenWidth, screenHeight, title.ptr);
    defer rl.closeWindow();

    var tmln = try Timeline.basic();
    var life_time_ms: f64 = 0;

    // kb input
    const n = 5;
    _ = n;
    const action_key = "qwert";
    var skill_keys = input.obtain_keys(action_key.len, action_key);

    // elements
    var exit = elems.Exiter.spawn(corner, rl.KeyboardKey.key_escape);
    exit.selfReference();

    const Rand = std.rand.DefaultPrng;
    var _rng = Rand.init(0);
    var rng = _rng.random();

    const pnt_num: u32 = 1024;
    const rows: u32 = 32;
    const cols: u32 = pnt_num / rows;
    const rowspace = 1.0 / @as(f32, @floatFromInt(rows));
    const colspace = 1.0 / @as(f32, @floatFromInt(cols));

    var info_on_surface = SurfaceInfo(pnt_num){ .tiles = undefined };
    for (0..pnt_num) |i| {
        const x = @as(f32, @floatFromInt(i / rows)) * colspace;
        const y = @as(f32, @floatFromInt(@mod(i, rows))) * rowspace;

        var tile: *repr.Tile = &info_on_surface.tiles[i];
        tile.pos = vf2{ x * screenWidth, y * screenHeight };
        tile.size = y * 15 + 5;
        tile.color = rl.Color.fromHSV(rng.float(f32) * 10, rng.float(f32), rng.float(f32));
    }

    var imgB = ImageBox{};
    imgB.imageLoadTry();

    // TODO: będę tu testował rendering obrazka
    // na przykład tworząc prosty system cząstekowy
    // gdzie particle sobie oscylują w różnych miejscach
    // to mógłby byś w pewnym sensie pewien benchmark wydajności
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

        exit.draw();

        const pointer_pos = rl.Vector3.init(mouse_pose[0], mouse_pose[1], 0);
        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);

        for (&info_on_surface.tiles) |*tile| repr.tBlob(tile.*);

        repr.frame(mouse_pose, false);
        const info_template: []const u8 = "Congrats! You created your first window!\n Frame time {d:.3}ms\n fps {d}\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{ delta_ms, 1000 / delta_ms });
        defer text_alloc.free(info);
        rl.drawText(info, 50, 50, 20, THEME[1]);
        imgB.repr();
    }
}
