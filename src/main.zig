const std = @import("std");
const rl = @import("raylib");

const Inst = std.time.Instant;

const TimeTool = struct {
    ts_start: Inst,
    ts_end: Inst,

    fn messureFrom(self: *TimeTool) !void {
        self.ts_start = try Inst.now();
    }

    fn messsureTo(self: *TimeTool) !void {
        self.ts_end = try Inst.now();
    }

    fn elapsedInfo(self: TimeTool) f64 {
        const elapsed_ns: f64 = @floatFromInt(self.ts_end.since(self.ts_start));
        const elapsed_ms = elapsed_ns / std.time.ns_per_ms;
        return elapsed_ms;
    }

    fn tickMs(self: *TimeTool) !f32 {
        try self.messsureTo();
        const time_delta_us = self.elapsedInfo();
        try self.messureFrom();
        return @floatCast(time_delta_us);
    }
};

fn FreshTimeTool() !TimeTool {
    const default_inst = try Inst.now();
    var tt = TimeTool{ .ts_start = default_inst, .ts_end = default_inst };
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
            .y = @intFromFloat(std.math.sin(osc.phase) * osc.amp),
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
};

fn raylib_loop() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alctr = gpa.allocator();

    const screenWidth = 800;
    const screenHeight = 450;
    var tt = try FreshTimeTool();

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    // rl.setTargetFPS(60);

    var red_circle = Circle.basicCircle();
    red_circle.pos = .{ .x = 100, .y = 200 };

    var main_osc = Osc.basicOsc();
    main_osc.amp = 25;

    var life_time_ms: f64 = 0;
    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(THEME[0]);

        const time_delta_ms = try tt.tickMs();

        main_osc.update(time_delta_ms);
        life_time_ms += @floatCast(time_delta_ms);

        const info_template = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(alctr, info_template, .{time_delta_ms});
        defer alctr.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(info, 50, 50, 20, THEME[1]);
        red_circle.draw(main_osc);
    }
}

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});
    try raylib_loop();
}
