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

const THEME = [_]rl.Color{ rl.Color.black, rl.Color.beige };

const Vec2i = struct {
    x: i32,
    y: i32,

    fn add(self: Vec2i, other: Vec2i) Vec2i {
        return Vec2i{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }
};

const Circle = struct {
    pos: Vec2i,
    color: rl.Color,
    height: i32,

    fn basicCircle() Circle {
        return Circle{
            .pos = .{ .x = 100, .y = 100 },
            .color = rl.Color.maroon,
            .height = 100,
        };
    }

    fn draw(self: Circle, osc: Osc) void {
        const osc_pos = Vec2i{
            .x = @intFromFloat(std.math.cos(osc.phase) * osc.amp),
            .y = @intFromFloat(std.math.sin(osc.phase) * osc.amp * 2),
        };
        const circle_pos = self.pos.add(osc_pos);
        const shadow_pos = Vec2i{
            .x = circle_pos.x,
            .y = self.pos.y + self.height,
        };
        rl.drawCircle(circle_pos.x, circle_pos.y, 20, self.color);
        rl.drawEllipse(shadow_pos.x, shadow_pos.y, 30, 5, THEME[1]);
    }
};

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

const Osc = struct {
    amp: f32,
    phase: f32,

    fn basicOsc() Osc {
        return Osc{
            .amp = 20,
            .phase = 0,
        };
    }

    fn update(self: *Osc, time_delta_ms: f32) void {
        const delta_s = time_delta_ms / std.time.ms_per_s;
        self.phase += delta_s * std.math.pi * 2;
    }

    fn updNonEd(self: Osc, time: f32) void {
        std.debug.print(" cos tam {d.3} cos tam {d.3}", .{ self.phase, time });
    }
};

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

    var life_time_ms: f64 = 0;
    // while (!rl.windowShouldClose()) {
    while (true) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);

        const time_delta_ms = try tt.tickMs();
        life_time_ms += @floatCast(time_delta_ms);

        const info_template = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(alctr, info_template, .{time_delta_ms});
        defer alctr.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(info, 50, 50, 20, THEME[1]);
        for (multiple_circles, &multiple_osc) |this_circle, *that_osc| {
            that_osc.update(time_delta_ms);
            this_circle.draw(that_osc.*);
        }
    }
}

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});
    try raylib_loop();
}
