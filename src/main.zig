const std = @import("std");
const rl = @import("raylib");
const rlui = @import("raygui");

const Allocator = std.mem.Allocator;
const Timeline = @import("mods/time.zig").Timeline;

const Circle = @import("mods/circle.zig").Circle;
const Osc = @import("mods/osc.zig").Osc;
const Vec2i = @import("mods/math.zig").Vec2i;
const THEME = @import("mods/circle.zig").THEME;

const TextInputModule = @import("mods/TextInputModule.zig");
const TxtEditor = TextInputModule.TextEditor;

fn createNCircles(comptime n: usize) [n]Circle {
    const result: [n]Circle = .{Circle{}} ** n;
    return result;
}

fn createNOsc(comptime n: usize) [n]Osc {
    const result: [n]Osc = .{Osc{}} ** n;
    return result;
}

const InputModule = @import("mods/InputModule.zig");
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

const math = @import("mods/math.zig");
const u2i = math.u2i;
const u2f = math.u2f;
const f2i = math.f2i;
const calcProgress = math.calcProgres;

const vi2 = math.vi2;
const vf2 = math.vf2;

const Space = struct {
    a: vf2 = @splat(0),
    b: vf2 = @splat(0),

    fn sample(self: Space, cords: f32) vf2 {
        const fac: vf2 = @splat(1 - cords);
        const rest: vf2 = @splat(cords);

        return self.a * fac + self.b * rest;
    }

    fn sample_i(self: Space, cords: f32) vi2 {
        const f_val = self.sample(cords);
        return vi2{ f2i(f_val[0]), f2i(f_val[1]) };
    }
};

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
    var skill_keys = InputModule.KbSignals(&keys, action_letters, n);
    var sig_arr = ExtractSignals(n, &skill_keys);

    WireSignals(n, &sig_arr, &cirlce_arr);
    const elo = cirlce_arr[0..n];
    _ = elo;

    const n_letters = 26;
    const letters: []const u8 = "qwertyuiopasdfghjklzxcvbnm";
    const letter_enums = InputModule.find_input_keys(letters, n_letters);
    var letter_keys = InputModule.KbSignals(&letter_enums, letters, n_letters);
    var txt_editor = try TxtEditor.spawn(arena);

    const num = @as(u32, n);

    const spot_a: vi2 = @splat(100);
    const spot_b: vi2 = @splat(344);

    const spc = Space{
        .a = spot_a,
        .b = spot_b,
    };

    for (0..n) |i| {
        const idx: u32 = @intCast(i);
        const progress = calcProgress(idx, num, true);

        const spot = spc.sample_i(progress);
        cirlce_arr[i].setPos(spot);

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
        for (&skill_keys) |*skill_key| skill_key.check_input(delta_ms);
        for (&cirlce_arr) |*circle| circle.update();

        for (&osc_arr) |*osc| osc.update(delta_ms);
        txt_editor.collectInput(&letter_keys, delta_ms);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);

        const mx = rl.getMouseX();
        const my = rl.getMouseY();

        const m_info_template: []const u8 = "Mouse posiotion {d:.3}, {d:.3}\n";
        const m_info = try std.fmt.allocPrintZ(text_alloc, m_info_template, .{ mx, my });
        defer text_alloc.free(m_info);

        const info_template: []const u8 = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{delta_ms});
        defer text_alloc.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(m_info, 50, 10, 20, THEME[1]);
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
