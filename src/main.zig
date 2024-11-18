const std = @import("std");
const rl = @import("raylib");
const rlui = @import("raygui");

const Inst = std.time.Instant;
const Timeline = @import("_time.zig").Timeline;

const Circle = @import("_circle.zig").Circle;
const Osc = @import("_osc.zig").Osc;
const Vec2i = @import("_math.zig").Vec2i;
const THEME = @import("_circle.zig").THEME;

fn createNCircles(comptime n: usize) [n]Circle {
    var result: [n]Circle = undefined;
    comptime var i = 0;
    inline while (i < n) : (i += 1) {
        result[i] = Circle.basicCircle();
    }
    return result;
}

fn createNOsc(comptime n: usize) [n]Osc {
    var result: [n]Osc = undefined;
    comptime var i = 0;
    inline while (i < n) : (i += 1) {
        result[i] = Osc.basicOsc();
    }
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
    for (key_enums, 0..) |key, i| {
        holds[i] = KbKey.basic(key);
    }

    return holds;
}

fn ExtractSignals(comptime n: usize, kb_keys: *[n]KbKey) [n]*Signal {
    var sig_arr: [n]*Signal = undefined;
    for (kb_keys, 0..) |*kb, i| sig_arr[i] = &kb.hold;
    return sig_arr;
}

fn WireSignals(comptime n: usize, sig_arr: *[n]*Signal, circle_arr: *[n]Circle) void {
    for (circle_arr, sig_arr) |*circle, sig| circle.sig = sig;
}

const Allocator = std.mem.Allocator;
const VF2 = @Vector(2, f32);

const ForTexting = struct {
    size: VF2 = .{ 300, 100 },
    pos: VF2 = .{ 400, 300 },
    text_memory: [:0]u8,

    fn basic(arena: Allocator) !ForTexting {
        var buffer = try arena.allocSentinel(u8, 64, 0);
        @memcpy(buffer[0..24], "cokolwiek by tu nie\nbylo");
        return ForTexting{ .text_memory = buffer };
    }

    fn draw(self: ForTexting) void {
        const rect = rl.Rectangle{
            .width = self.size[0],
            .height = self.size[1],
            .x = self.pos[0],
            .y = self.pos[1],
        };
        _ = rlui.guiTextBox(rect, self.text_memory.ptr, 82, false);
    }
};

fn simulation(text_alloc: Allocator, arena: Allocator) !void {
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    var tmln = try Timeline.basic();
    // rl.setTargetFPS(59);

    const n = 5;
    const reactive_letters = "qwert";
    const keys = InputModule.find_input_keys(reactive_letters, n);
    var kb_keys = InputModule.KbSignals(&keys, n);
    var sig_arr = ExtractSignals(n, &kb_keys);
    var osc_arr = createNOsc(n);
    var cirlce_arr = createNCircles(n);
    WireSignals(n, &sig_arr, &cirlce_arr);

    var prompt_box = try ForTexting.basic(arena);
    const n_letters = 26;
    const letters: []const u8 = "qwertyuiopasdfghjklzxcvbnm";
    const letter_keys = InputModule.find_input_keys(letters, n_letters);
    _ = InputModule.KbSignals(&letter_keys, n_letters);

    const num = @as(u32, n);
    const init_pos = Vec2i{
        .x = 100,
        .y = 100,
    };

    for (0..n) |i| {
        const idx: u32 = @intCast(i);
        const progress = calcProgres(idx, num, true);

        const inst_x = init_pos.x + u2i(idx) * 100;
        cirlce_arr[i].pos = Vec2i{ .x = inst_x, .y = init_pos.y };

        const phase = progress * 0.5;
        osc_arr[i].phase = phase;
    }

    var life_time_ms: f64 = 0;

    var exit_key = KbKey.esc_hold();
    const exit_signal = &exit_key.hold;
    while (exit_signal.get() == false) {
        // exit_key.check_input();

        for (&kb_keys) |*key_from_kb| key_from_kb.check_input();
        for (&cirlce_arr) |*circle| circle.update();

        const time_delta_ms = try tmln.tickMs();
        life_time_ms += @floatCast(time_delta_ms);
        for (&osc_arr) |*osc| {
            osc.update(time_delta_ms);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);

        const info_template = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{time_delta_ms});
        defer text_alloc.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(info, 50, 50, 20, THEME[1]);
        for (cirlce_arr, osc_arr) |this_circle, that_osc| {
            this_circle.draw(that_osc);
        }

        const btn_loc = rl.Rectangle{ .height = 100, .width = 300, .x = 100, .y = 300 };
        _ = rlui.guiButton(btn_loc, "Halo, da się mnie kliknąć?");

        prompt_box.draw();
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

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});
    try simulation_warmup();
}

test {
    std.testing.refAllDecls(@This());
}
