const std = @import("std");
const rl = @import("raylib");
const rlui = @import("raygui");

const Allocator = std.mem.Allocator;
const Timeline = @import("mods/time.zig").Timeline;

const Circle = @import("mods/circle.zig").Circle;
const Osc = @import("mods/osc.zig").Osc;
const Vec2i = @import("mods/core/math.zig").Vec2i;
const THEME = @import("mods/circle.zig").THEME;

const TextInputModule = @import("mods/TextInputModule.zig");
const TxtEditor = TextInputModule.TextEditor;

const InputModule = @import("mods/input.zig");
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

fn WireSignals(circle_arr: []Circle, sig_arr: []*Signal) void {
    for (circle_arr, sig_arr) |*circle, sig| circle.sig = sig;
}

const math = @import("mods/core/math.zig");
const vi2 = math.vi2;
const vf2 = math.vf2;

const LinSpace = @import("spatial.zig").LinSpace;
const SpaceSim = struct {
    const Self = @This();
    crcls: []Circle,
    oscs: []Osc,
    prog: []const f32,

    fn sample_phase(self: Self) void {
        for (self.prog, self.oscs) |prog, *osc| {
            const phase = prog * 6;
            osc.phase = phase;
        }
    }

    fn sample_circles(self: Self, lin_space: LinSpace) void {
        for (self.prog, self.crcls) |prog, *circle| {
            const spot = lin_space.sample_i(prog);
            circle.setPos(spot);
        }
    }

    fn draw(self: Self) void {
        for (self.crcls, self.oscs) |this_circle, that_osc| {
            this_circle.draw(that_osc);
        }
    }
};

const Slider = struct {
    pos: u32 = 0,
    max: u32 = 2,
    min: u32 = 0,

    fn up(sldr: *Slider) void {
        if (sldr.pos != sldr.max) sldr.pos += 1;
    }

    fn down(sldr: *Slider) void {
        if (sldr.pos != sldr.min) sldr.pos -= 1;
    }
};

const input = @import("mods/input.zig");

fn draw_rectangle(spot: vi2, active: bool) void {
    const defCol = if (active) rl.Color.yellow else rl.Color.dark_green;
    rl.drawRectangle(spot[0] - 25, spot[1] - 25, 50, 50, defCol);
}

fn log_slice_info(slice: []f32) void {
    std.debug.print("---\n", .{});
    for (slice) |num_val| {
        std.debug.print(" num value is: {d:.2}\n", .{num_val});
    }
}

const spt = @import("spatial.zig");

const phys = @import("mods/phys.zig");
const Iner = phys.Inertia;
const PhysInprnt = phys.PhysInprint;

fn simulation(text_alloc: Allocator, arena: Allocator) !void {
    _ = arena;
    const screenWidth = 800;
    const screenHeight = 450;

    const tile: [:0]const u8 = "raylib-zig [core] example - basic window";

    rl.initWindow(screenWidth, screenHeight, tile.ptr);
    defer rl.closeWindow();

    var tmln = try Timeline.basic();
    // rl.setTargetFPS(59);

    const n = 5;
    const m = n + 6;

    var cirlce_arr = Circle.createN(m);
    var osc_arr = Osc.createN(m);

    const without_tips = spt.progOps{ .len = m, .first = false, .last = false };
    const progress_marks: []const f32 = &spt.linProg(without_tips);
    const my_sim = SpaceSim{
        .crcls = cirlce_arr[0..m],
        .oscs = osc_arr[0..m],
        .prog = progress_marks,
    };

    const action_key = "qwert";
    const action_len = action_key.len;
    const keys = InputModule.find_key_mapping(action_key, action_len);
    var skill_keys = InputModule.KbSignals(&keys, action_key, n);

    var skill_signals = ExtractSignals(n, &skill_keys);
    WireSignals(cirlce_arr[0..n], skill_signals[0..n]);

    const n_letters = 26;
    const letters: []const u8 = "qwertyuiopasdfghjklzxcvbnm";
    const letter_enums = InputModule.find_key_mapping(letters, n_letters);
    var letter_keys = InputModule.KbSignals(&letter_enums, letters, n_letters);
    // var txt_editor = try TxtEditor.spawn(arena);

    const spot_a: vi2 = @splat(100);
    const spot_b: vi2 = @splat(344);

    var lin_spc = LinSpace{
        .a = spot_a,
        .b = spot_b,
    };

    my_sim.sample_phase();
    my_sim.sample_circles(lin_spc);

    var life_time_ms: f64 = 0;

    var inertia_start = Iner.spawn(lin_spc.a);
    var inertia_end = Iner.spawn(lin_spc.b);

    var exit_key = KbKey.init(rl.KeyboardKey.key_escape, 0);
    const exit_signal = &exit_key.hold.base;

    var phx = PhysInprnt{};
    phx.reecalc();
    const inerts = &[_]*Iner{
        &inertia_start,
        &inertia_end,
    };
    for (inerts) |singl_one| singl_one.phx = &phx;

    var sldr = Slider{ .max = 1 };
    while (exit_signal.get() == false) {
        // exit_key.check_input();
        const delta_ms = try tmln.tickMs();
        life_time_ms += @floatCast(delta_ms);

        for (&letter_keys) |*key_from_kb| key_from_kb.check_input(delta_ms);
        for (&skill_keys) |*skill_key| skill_key.check_input(delta_ms);
        for (&cirlce_arr) |*circle| circle.update();

        for (&osc_arr) |*osc| osc.update(delta_ms);

        // txt_editor.collectInput(&letter_keys, delta_ms);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(THEME[0]);

        // selection and movement control
        if (skill_signals[2].get()) sldr.down() else if (skill_signals[3].get()) sldr.up();
        if (skill_signals[0].get()) inerts[sldr.pos].setTarget(input.sample_mouse());

        for (inerts) |inertia_point| inertia_point.simulate();

        lin_spc.a = inerts[0].getPos();
        lin_spc.b = inerts[1].getPos();

        my_sim.sample_circles(lin_spc);
        my_sim.draw();

        draw_rectangle(lin_spc.sample_i(0), sldr.pos == 0);
        draw_rectangle(lin_spc.sample_i(1), sldr.pos == 1);

        const info_template: []const u8 = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{delta_ms});
        defer text_alloc.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(info, 50, 50, 20, THEME[1]);
        // rl.drawText(txt_editor.cStr(), 50, 70, 20, THEME[1]);

        // const btn_loc = rl.Rectangle{ .height = 100, .width = 300, .x = 100, .y = 300 };
        // _ = rlui.guiButton(btn_loc, "Halo, da się mnie kliknąć?");
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

const examples = enum {
    raylib,
    jtinker,
};

pub fn main() !void {
    const selector: examples = .raylib;
    switch (selector) {
        .raylib => {
            std.debug.print("raylib using zig!\n", .{});
            try simulation_warmup();
        },
        .jtinker => {
            const explore_fn = @import("explore/prompt.zig").fs_explorer;
            std.debug.print("tinkering around a json!\n", .{});
            try explore_fn();
        },
    }
}

test {
    std.testing.refAllDecls(@This());
}
