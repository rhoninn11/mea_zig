const std = @import("std");
const rl = @import("raylib");
const rlui = @import("raygui");

const Allocator = std.mem.Allocator;
const Timeline = @import("_time.zig").Timeline;

const Circle = @import("_circle.zig").Circle;
const Osc = @import("_osc.zig").Osc;
const Vec2i = @import("_math.zig").Vec2i;
const THEME = @import("_circle.zig").THEME;

const TextInputModule = @import("modules/TextInputModule.zig");
const TxtEditor = TextInputModule.TextEditor;

fn createNCircles(comptime n: usize) [n]Circle {
    const result: [n]Circle = .{Circle{}} ** n;
    return result;
}

fn createNOsc(comptime n: usize) [n]Osc {
    const result: [n]Osc = .{Osc{}} ** n;
    return result;
}

fn u2f(a: u32) f32 {
    return @as(f32, @floatFromInt(a));
}

fn u2i(a: u32) i32 {
    return @as(i32, @intCast(a));
}

fn calcProgres(i: u32, n: u32, closed: bool) f32 {
    const dol = if (closed) n - 1 else n;
    return u2f(i) / u2f(dol);
}
const InputModule = @import("modules/InputModule.zig");
const Signal = InputModule.Signal;
const KbKey = InputModule.KbKey;

fn KBSignals(comptime n: usize, key_enums: [n]rl.KeyboardKey) ![n]KbKey {
    var holds: [n]KbKey = undefined;
    for (key_enums, 0..) |key, i| holds[i] = KbKey.init(key);
    return holds;
}

fn ExtractSignals(comptime n: usize, kb_keys: *[n]KbKey) [n]*Signal {
    var sig_arr: [n]*Signal = undefined;
    for (kb_keys, 0..) |*kb, i| sig_arr[i] = &kb.hold.base;
    return sig_arr;
}

fn WireSignals(comptime n: usize, sig_arr: *[n]*Signal, circle_arr: *[n]Circle) void {
    for (circle_arr, sig_arr) |*circle, sig| circle.sig = sig;
}

const vi2 = @import("_math.zig").vi2;

fn simulation(text_alloc: Allocator, arena: Allocator) !void {
    const screenWidth = 800;
    const screenHeight = 450;

    const tile: [:0]const u8 = "raylib-zig [core] example - basic window";

    rl.initWindow(screenWidth, screenHeight, tile.ptr);
    defer rl.closeWindow();

    var tmln = try Timeline.basic();
    // rl.setTargetFPS(59);

    const n = 5;

    var cirlce_arr = createNCircles(n);
    var osc_arr = createNOsc(n);
    const action_letters = "qwert";
    const keys = InputModule.find_input_keys(action_letters, n);
    var kb_keys = InputModule.KbSignals(&keys, action_letters, n);
    var sig_arr = ExtractSignals(n, &kb_keys);

    WireSignals(n, &sig_arr, &cirlce_arr);

    const n_letters = 26;
    const letters: []const u8 = "qwertyuiopasdfghjklzxcvbnm";
    const letter_enums = InputModule.find_input_keys(letters, n_letters);
    var letter_keys = InputModule.KbSignals(&letter_enums, letters, n_letters);
    var txt_editor = try TxtEditor.spawn(arena);

    const num = @as(u32, n);

    const first_spot = vi2{ 100, 100 };
    const offset = 100;

    for (0..n) |i| {
        const idx: u32 = @intCast(i);
        const progress = calcProgres(idx, num, true);
        const local_offset = offset * u2i(idx);
        const delta = vi2{ local_offset, 0 };

        cirlce_arr[i].setPos(first_spot + delta);

        const phase = progress * 0.5;
        osc_arr[i].phase = phase;
    }

    var life_time_ms: f64 = 0;

    var exit_key = KbKey.init(rl.KeyboardKey.key_escape, 0);
    const exit_signal = &exit_key.hold.base;
    while (exit_signal.get() == false) {
        // exit_key.check_input();
        const delta_ms = try tmln.tickMs();
        life_time_ms += @floatCast(delta_ms);

        for (&letter_keys) |*key_from_kb| key_from_kb.check_input(delta_ms);
        for (&kb_keys) |*key_from_kb| key_from_kb.check_input(delta_ms);
        for (&cirlce_arr) |*circle| circle.update();

        for (&osc_arr) |*osc| osc.update(delta_ms);
        txt_editor.collectInput(&letter_keys, delta_ms);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);

        const info_template: []const u8 = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{delta_ms});
        defer text_alloc.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(info, 50, 50, 20, THEME[1]);
        rl.drawText(txt_editor.cStr(), 50, 70, 20, THEME[1]);
        for (cirlce_arr, osc_arr) |this_circle, that_osc| {
            this_circle.draw(that_osc);
        }

        const btn_loc = rl.Rectangle{ .height = 100, .width = 300, .x = 100, .y = 300 };
        _ = rlui.guiButton(btn_loc, "Halo, da się mnie kliknąć?");
    }
}

fn simulation_warmup() !void {
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

    try simulation(fmt_alloc, arena);
}

const Prompt = struct {
    prompt: []u8,
};

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});
    try simulation_warmup();

    // const explore_fn = @import("explore/filesystem.zig").fs_explorer;
    // try explore_fn();
}

test {
    std.testing.refAllDecls(@This());
}
