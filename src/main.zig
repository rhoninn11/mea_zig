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

const input = @import("mods/input.zig");
const Signal = input.Signal;
const KbKey = input.KbKey;

fn obtain_keys(comptime n: usize, comptime letters: *const [n:0]u8) [n]KbKey {
    const key_n = letters.len;
    const keys = input.find_key_mapping(letters, key_n);
    return input.KbSignals(&keys, letters, key_n);
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

    fn init_phase(self: Self) void {
        for (self.prog, self.oscs) |prog, *osc| {
            const phase = prog * 6;
            osc.phase = phase;
        }
    }

    fn sample_circles(self: Self, lin_space: LinSpace) void {
        for (self.prog, self.crcls) |prog, *circle| {

            // std.debug.print("value is: {d}\n", .{cords});
            const spot = lin_space.sample_i(prog);
            circle.setPos(spot);
        }
    }

    fn draw(self: Self) void {
        for (self.crcls, self.oscs) |this_circle, that_osc| {
            this_circle.draw(that_osc);
        }
    }

    fn update(self: *Self, td: f32) void {
        for (self.oscs) |*osc| osc.update(td);
        for (self.crcls) |*crcl| crcl.update();
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
const PhysInprint = phys.PhysInprint;

const ImageBox = @import("ImageBox.zig");
var img_box = ImageBox{};

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
    // img_box.imageLoadTry();
    try simulation(fmt_alloc, arena);
}

fn simulation(text_alloc: Allocator, arena: Allocator) !void {
    _ = arena;
    const screenWidth = 800;
    const screenHeight = 450;

    const tile: [:0]const u8 = "raylib-zig [core] example - basic window";

    rl.initWindow(screenWidth, screenHeight, tile.ptr);
    defer rl.closeWindow();

    var tmln = try Timeline.basic();
    // rl.setTargetFPS(59);

    const letters = "qwertyuiopasdfghjklzxcvbnm";
    var letter_keys = obtain_keys(letters.len, letters);

    const n = 5;
    const action_key = "qwert";
    var skill_keys = obtain_keys(action_key.len, action_key);

    const m = n + 6;
    std.debug.assert(m >= n);

    var cirlce_arr = Circle.createN(m);
    var skill_signals = ExtractSignals(n, &skill_keys);
    WireSignals(cirlce_arr[0..n], skill_signals[0..n]);

    var osc_arr = Osc.createN(m);
    // var txt_editor = try TxtEditor.spawn(arena);

    const spot_a: vi2 = @splat(100);
    const spot_b: vi2 = vi2{ 700, 100 };

    const stage = spt.LinStage(m);
    var lin_spc = spt.LinSpace{
        .a = spot_a,
        .b = spot_b,
    };

    // można by zaplanować ograniczoną ilość takich segmentów
    var my_sim = SpaceSim{
        .crcls = cirlce_arr[0..m],
        .oscs = osc_arr[0..m],
        .prog = stage.middle,
    };
    my_sim.init_phase();
    my_sim.sample_circles(lin_spc);

    var life_time_ms: f64 = 0;

    var inertia_start = Iner.spawn(lin_spc.a);
    var inertia_end = Iner.spawn(lin_spc.b);
    var pointer_inert = Iner.spawn(vf2{ 0, 0 });

    var exit_key = KbKey.init(rl.KeyboardKey.key_escape, 0);
    const exit_signal = &exit_key.hold.base;

    var phx = PhysInprint{};
    var pointer_phx = PhysInprint.new(5, 0.33, 1);
    phx.reecalc();
    const inerts = &[_]*Iner{
        &inertia_start,
        &inertia_end,
        &pointer_inert,
    };
    for (inerts) |singl_one| singl_one.phx = &phx;
    pointer_inert.phx = &pointer_phx;

    var sldr = Slider{ .max = 1 };
    while (exit_signal.get() == false) {
        // exit_key.check_input();
        const delta_ms = try tmln.tickMs();
        life_time_ms += @floatCast(delta_ms);

        const mouse_pose = input.sample_mouse();
        pointer_inert.setTarget(mouse_pose);

        for (&letter_keys) |*key_from_kb| key_from_kb.check_input(delta_ms);
        for (&skill_keys) |*skill_key| skill_key.check_input(delta_ms);
        if (skill_signals[2].get()) sldr.down() else if (skill_signals[3].get()) sldr.up();
        if (skill_signals[0].get()) inerts[sldr.pos].setTarget(mouse_pose);

        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(THEME[0]);

        for (inerts) |inertia_point| inertia_point.simulate(delta_ms);

        lin_spc.a = inerts[0].getPos();
        lin_spc.b = inerts[1].getPos();

        my_sim.update(delta_ms);
        my_sim.sample_circles(lin_spc);
        my_sim.draw();

        draw_rectangle(lin_spc.sample_i(0), sldr.pos == 0);
        draw_rectangle(lin_spc.sample_i(1), sldr.pos == 1);

        const info_template: []const u8 = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{delta_ms});
        defer text_alloc.free(info);

        rl.drawText(info, 50, 50, 20, THEME[1]);
        const tmp = pointer_inert.getPos();
        const pointer_pos = rl.Vector3.init(tmp[0], tmp[1], 0);
        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);
        // img_box.drawRepr();
    }
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
