const std = @import("std");
const rl = @import("raylib");

const math = @import("math.zig");
const core = @import("core.zig");
const repr = @import("../mods/core/repr.zig");

const input = @import("../mods/input.zig");
const spt = @import("../spatial.zig");
const LinePreset = spt.LinePreset;

const Timeline = @import("../mods/time.zig").Timeline;

const Circle = @import("../mods/circle.zig").Circle;
const Osc = @import("osc.zig").Osc;

const THEME = repr.Theme;
const Allocator = std.mem.Allocator;

const Signal = input.Signal;
const KbKey = input.KbKey;

const LinSpace = spt.DynLinSpace;
const SpaceSim = struct {
    const Self = @This();
    crcls: []Circle,
    oscs: []Osc,
    progress_bar: []const f32,
    len: u8,
    dyn_space: *spt.DynLinSpace,

    fn init_phase(self: Self) void {
        for (self.progress_bar, self.oscs) |prog, *osc| {
            const phase = prog * 6;
            osc.phase = phase;
        }
    }

    fn sample_circles(self: *const Self) void {
        for (self.progress_bar, self.crcls) |pb, *circle| {

            // std.debug.print("value is: {d}\n", .{cords});
            const sim_spot = self.dyn_space.sample(pb);
            circle.setPos(sim_spot);
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
        self.sample_circles();
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

fn log_slice_info(slice: []f32) void {
    std.debug.print("---\n", .{});
    for (slice) |num_val| {
        std.debug.print(" num value is: {d:.2}\n", .{num_val});
    }
}

const phys = @import("phys.zig");
const Iner = phys.Inertia;
const PhysInprint = phys.PhysInprint;
const Exiter = @import("../mods/elements.zig").Exiter;

const AppMemory = core.AppMemory;

pub fn launchAppWindow(aloc: *const AppMemory, win: *core.RLWindow) !void {
    return _simulation(aloc.arena, win);
}
pub fn program(aloc: *const AppMemory) void {
    _ = _simulation(aloc) catch {
        std.debug.print("error cleaning\n", .{});
    };
}

fn _simulation(alloc: std.mem.Allocator, win: *core.RLWindow) !void {
    _ = alloc;

    var exit = Exiter.spawn(win.corner, rl.KeyboardKey.escape);
    exit.selfReference();

    var timeline = try Timeline.init();
    // rl.setTargetFPS(59);

    const letters = "qwertyuiopasdfghjklzxcvbnm";
    var letter_keys = input.obtain_keys(letters.len, letters);

    const action_key = "qwert";
    const n: comptime_int = action_key.len;
    var skill_keys = input.obtain_keys(action_key.len, action_key);

    const m = n + 6;
    std.debug.assert(m >= n);

    var cirlce_arr = Circle.createN(m);
    var skill_signals = input.extractSignals(n, &skill_keys);
    Circle.WireSignals(cirlce_arr[0..n], skill_signals[0..n]);

    var osc_arr = Osc.createN(m);

    // można by zaplanować ograniczoną ilość takich segmentów
    var lin_spc = spt.DynLinSpace{
        .a = @splat(100),
        .b = .{ 700, 100 },
    };

    var spread = spt.LinStage(m, LinePreset.NoTip);
    var my_sim = SpaceSim{
        .dyn_space = &lin_spc,
        .progress_bar = spread[0..m],
        .crcls = cirlce_arr[0..m],
        .oscs = osc_arr[0..m],
        .len = m,
    };

    my_sim.init_phase();
    my_sim.update(0);

    var life_time_ms: f64 = 0;

    var inertia_start = Iner.init(lin_spc.a);
    var inertia_end = Iner.init(lin_spc.b);
    var pointer_inert = Iner.init(.{ 0, 0 });

    const phx = PhysInprint.default();
    const pointer_phx = PhysInprint.new(5, 0.33, 1);

    const inerts = &[_]*Iner{
        &inertia_start,
        &inertia_end,
        &pointer_inert,
    };
    for (inerts) |singl_one| singl_one.phx = phx;
    pointer_inert.phx = pointer_phx;

    const info_template: []const u8 = "Congrats! You created your first window! Frame time {d:.3} ms\n";
    var fmt_memory: [1024]u8 = undefined;
    const fmt_buf = fmt_memory[0..];

    var sldr = Slider{ .max = 1 };
    while (exit.toContinue()) {
        // exit_key.check_input();
        const delta_ms = timeline.tickMs();

        life_time_ms += @floatCast(delta_ms);

        const mouse_pose = input.sample_mouse();
        pointer_inert.in(mouse_pose);

        for (&letter_keys) |*key_from_kb| key_from_kb.collectiInput();
        for (&skill_keys, 0..) |*skill_key, i| {
            // std.debug.print("{d} {s}\n", .{ i, @tagName(skill_key.*.key) });
            _ = i;
            skill_key.collectiInput();
        }
        exit.collectInput();

        if (skill_signals[2].get()) sldr.down() else if (skill_signals[3].get()) sldr.up();
        if (skill_signals[0].get()) inerts[sldr.pos].in(mouse_pose);

        for (inerts) |inertia_point| {
            inertia_point.simulate(delta_ms);
        }
        lin_spc.a = inerts[0].out();
        lin_spc.b = inerts[1].out();

        my_sim.update(delta_ms);
        // my_sim.sample_circles(lin_spc);
        my_sim.draw();
        exit.update(delta_ms);

        const info = try std.fmt.bufPrintZ(fmt_buf, info_template, .{delta_ms});

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);
        repr.frame(lin_spc.sample(0), sldr.pos == 0);
        repr.frame(lin_spc.sample(1), sldr.pos == 1);

        rl.drawText(info, 50, 50, 20, THEME[1]);
        const tmp = pointer_inert.out();
        const pointer_pos = rl.Vector3.init(tmp[0], tmp[1], 0);
        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);
        // img_box.drawRepr();

        exit.draw();
    }
}
