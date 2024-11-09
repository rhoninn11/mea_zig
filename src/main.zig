const std = @import("std");
const rl = @import("raylib");

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

const rlKey = rl.KeyboardKey;

const signalB = struct {
    state: bool,

    fn basic() signalB {
        return signalB{
            .state = false,
        };
    }

    fn set(self: *signalB, b: bool) void {
        // if (self.state != b) {
        //     std.debug.print("hold state change from {}\n", .{self.state});
        // }
        self.state = b;
    }

    fn get(self: signalB) bool {
        return self.state;
    }
};

const keyHold = struct {
    hold: *signalB,
    key: rlKey,

    fn space_bar(s: *signalB) keyHold {
        return keyHold{
            .hold = s,
            .key = rlKey.key_space,
        };
    }
    fn basicKeyHold(s: *signalB, k: rl.KeyboardKey) keyHold {
        return keyHold{
            .hold = s,
            .key = k,
        };
    }

    fn check_input(self: *keyHold) void {
        self.hold.set(rl.isKeyDown(self.key));
    }
};

const Signalet = struct {
    sig: *signalB,
    key_hld: *keyHold,
};

fn keysToKeyHold(arena: std.mem.Allocator, comptime n: usize, keys: [n]rl.KeyboardKey) ![n]Signalet {
    var holds: [n]Signalet = undefined;

    var signals = try arena.alloc(signalB, n);
    var keyHolds = try arena.alloc(keyHold, n);

    for (keys, 0..) |key, i| {
        signals[i] = signalB.basic();
        keyHolds[i] = keyHold.basicKeyHold(&signals[i], key);

        holds[i] = Signalet{
            .sig = &signals[i],
            .key_hld = &keyHolds[i],
        };
    }

    return holds;
}

fn color_switch(b: bool) rl.Color {
    return switch (b) {
        false => rl.Color.maroon,
        true => rl.Color.dark_purple,
    };
}

fn raylib_loop() !void {
    var fmt_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const fmt_alloc = fmt_gpa.allocator();
    defer _ = fmt_gpa.deinit();

    var obj_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_arena = std.heap.ArenaAllocator.init(obj_gpa.allocator());
    const arena = obj_arena.allocator();
    defer _ = obj_arena.deinit();

    const screenWidth = 800;
    const screenHeight = 450;
    var tmln = try Timeline.basic();

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    // rl.setTargetFPS(60);

    const n = 4;
    var multiple_circles = createNCircles(n);
    var multiple_osc = createNOsc(n);

    const keys = .{ rl.KeyboardKey.key_q, rl.KeyboardKey.key_w, rl.KeyboardKey.key_e, rl.KeyboardKey.key_r };
    const holds = try keysToKeyHold(arena, 4, keys);

    const num = @as(u32, n);
    const init_pos = Vec2i{
        .x = 100,
        .y = 100,
    };

    for (0..n) |i| {
        const idx: u32 = @intCast(i);
        const progress = calcProgres(idx, num, true);

        const inst_x = init_pos.x + u2i(idx) * 100;
        multiple_circles[i].pos = Vec2i{ .x = inst_x, .y = init_pos.y };

        const phase = progress * 0.5;
        multiple_osc[i].phase = phase;
    }

    var life_time_ms: f64 = 0;
    // while (!rl.windowShouldClose()) {
    while (true) {
        for (&multiple_circles, holds) |*circle, hold| {
            hold.key_hld.check_input();
            const tmp_col = color_switch(hold.sig.get());
            circle.setColor(tmp_col);
        }

        const time_delta_ms = try tmln.tickMs();
        life_time_ms += @floatCast(time_delta_ms);
        for (&multiple_osc) |*osc| {
            osc.update(time_delta_ms);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);

        const info_template = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(fmt_alloc, info_template, .{time_delta_ms});
        defer fmt_alloc.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(info, 50, 50, 20, THEME[1]);
        for (multiple_circles, multiple_osc) |this_circle, that_osc| {
            this_circle.draw(that_osc);
        }
    }
}

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});
    try raylib_loop();
}
