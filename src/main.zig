const std = @import("std");
const rl = @import("raylib");

const Inst = std.time.Instant;

const Timeline = struct {
    then: Inst,

    fn basic() !Timeline {
        const timespace = try Inst.now();
        return Timeline{
            .then = timespace,
        };
    }

    fn messureFrom(self: *Timeline) !void {
        self.then = try Inst.now();
    }

    fn elapsedInfo(self: Timeline) !f64 {
        const now = try Inst.now();
        const elapsed_ns: f64 = @floatFromInt(now.since(self.then));
        const elapsed_ms = elapsed_ns / std.time.ns_per_ms;
        return elapsed_ms;
    }

    fn tickMs(self: *Timeline) !f32 {
        const time_delta_us = try self.elapsedInfo();
        try self.messureFrom();
        return @floatCast(time_delta_us);
    }
};

fn FreshTimeTool() !Timeline {
    const default_inst = try Inst.now();
    var tt = Timeline{ .then = default_inst, .ts_end = default_inst };
    try tt.messureFrom();
    return tt;
}

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

    fn check_input(self: *keyHold) void {
        self.hold.set(rl.isKeyDown(self.key));
    }
};

fn raylib_loop() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alctr = gpa.allocator();

    const screenWidth = 800;
    const screenHeight = 450;
    var tt = try Timeline.basic();

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    // rl.setTargetFPS(60);

    const n = 5;
    var multiple_circles = createNCircles(n);
    var multiple_osc = createNOsc(n);

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

    var color_change_signal = signalB{ .state = false };
    var spacebar = keyHold.space_bar(&color_change_signal);

    var life_time_ms: f64 = 0;
    // while (!rl.windowShouldClose()) {
    while (true) {
        spacebar.check_input();

        const new_color = switch (color_change_signal.get()) {
            false => rl.Color.maroon,
            true => rl.Color.dark_purple,
        };

        multiple_circles[0].setColor(new_color);

        const time_delta_ms = try tt.tickMs();
        life_time_ms += @floatCast(time_delta_ms);
        for (&multiple_osc) |*osc| {
            osc.update(time_delta_ms);
        }

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);

        const info_template = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(alctr, info_template, .{time_delta_ms});
        defer alctr.free(info);

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
