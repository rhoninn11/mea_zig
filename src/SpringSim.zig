const std = @import("std");
const rl = @import("raylib");

const math = @import("mods/core/math.zig");
const repr = @import("mods/core/repr.zig");

const input = @import("mods/input.zig");
const spt = @import("spatial.zig");

const Timeline = @import("mods/time.zig").Timeline;

const Circle = @import("mods/circle.zig").Circle;
const Osc = @import("mods/osc.zig").Osc;

const THEME = @import("mods/circle.zig").THEME;
const Allocator = std.mem.Allocator;

const Signal = input.Signal;
const KbKey = input.KbKey;

const vi2 = math.vi2;
const vf2 = math.vf2;

const LinSpace = spt.LinSpace;
const SpaceSim = struct {
    const Self = @This();
    crcls: []Circle,
    oscs: []Osc,
    prog: []const f32,
    len: u8,

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

fn log_slice_info(slice: []f32) void {
    std.debug.print("---\n", .{});
    for (slice) |num_val| {
        std.debug.print(" num value is: {d:.2}\n", .{num_val});
    }
}

const phys = @import("mods/phys.zig");
const Iner = phys.Inertia;
const PhysInprint = phys.PhysInprint;
const Exiter = @import("mods/elements.zig").Exiter;

const AppMemory = @import("core.zig").AppMamory;
pub fn program(aloc: *const AppMemory) void {
    _ = _simulation(aloc) catch {
        std.debug.print("error cleaning\n", .{});
    };
}

fn _simulation(aloc: *const AppMemory) !void {
    const arena = aloc.arena;
    const text_alloc = aloc.gpa;

    _ = arena;
    const screenWidth = 800;
    const screenHeight = 450;

    const tile: [:0]const u8 = "raylib-zig [core] example - basic window";
    rl.initWindow(screenWidth, screenHeight, tile.ptr);
    defer rl.closeWindow();

    const corner = math.vf2{ screenWidth, 0 };
    var exit = Exiter.spawn(corner, rl.KeyboardKey.key_escape);
    exit.selfReference();

    var tmln = try Timeline.basic();
    // rl.setTargetFPS(59);

    const letters = "qwertyuiopasdfghjklzxcvbnm";
    var letter_keys = input.obtain_keys(letters.len, letters);

    const n = 5;
    const action_key = "qwert";
    var skill_keys = input.obtain_keys(action_key.len, action_key);

    const m = n + 6;
    std.debug.assert(m >= n);

    var cirlce_arr = Circle.createN(m);
    var skill_signals = input.extractSignals(n, &skill_keys);
    Circle.WireSignals(cirlce_arr[0..n], skill_signals[0..n]);

    var osc_arr = Osc.createN(m);

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
        .len = m,
    };

    my_sim.init_phase();
    my_sim.sample_circles(lin_spc);

    var life_time_ms: f64 = 0;

    var inertia_start = Iner.spawn(lin_spc.a);
    var inertia_end = Iner.spawn(lin_spc.b);
    var pointer_inert = Iner.spawn(vf2{ 0, 0 });

    var phx = PhysInprint{};
    phx.reecalc();
    var pointer_phx = PhysInprint.new(5, 0.33, 1);

    const inerts = &[_]*Iner{
        &inertia_start,
        &inertia_end,
        &pointer_inert,
    };
    for (inerts) |singl_one| singl_one.phx = &phx;
    pointer_inert.phx = &pointer_phx;

    var sldr = Slider{ .max = 1 };
    while (exit.toContinue()) {
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
        exit.update(delta_ms);

        repr.frame(lin_spc.sample(0), sldr.pos == 0);
        repr.frame(lin_spc.sample(1), sldr.pos == 1);

        const info_template: []const u8 = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{delta_ms});
        defer text_alloc.free(info);

        rl.drawText(info, 50, 50, 20, THEME[1]);
        const tmp = pointer_inert.getPos();
        const pointer_pos = rl.Vector3.init(tmp[0], tmp[1], 0);
        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);
        // img_box.drawRepr();

        exit.draw();
    }
}
