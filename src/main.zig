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

    fn tickMs(self: *TimeTool) !f64 {
        try self.messsureTo();
        const time_delta_us = self.elapsedInfo();
        try self.messureFrom();
        return time_delta_us;
    }
};

fn FreshTimeTool() !TimeTool {
    const default_inst = try Inst.now();
    var tt = TimeTool{ .ts_start = default_inst, .ts_end = default_inst };
    try tt.messureFrom();
    return tt;
}

fn raylib_loop() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alctr = gpa.allocator();

    const screenWidth = 800;
    const screenHeight = 450;
    var tt = try FreshTimeTool();

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");
    defer rl.closeWindow();

    rl.setTargetFPS(60);
    // !rl.windowShouldClose() - but it broke in wsl so i just use some time until close

    var life_time_ms: f64 = 0;
    while (life_time_ms / std.time.ms_per_s < 10) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.white);

        const time_delta_ms = try tt.tickMs();

        life_time_ms += time_delta_ms;

        const info_template = "Congrats! You created your first window! Frame time {d:.3} ms\n";
        const info = try std.fmt.allocPrintZ(alctr, info_template, .{time_delta_ms});
        defer alctr.free(info);

        // std.debug.print(info_template, .{time_delta_ms});
        rl.drawText(info, 50, 50, 20, rl.Color.light_gray);

        const s_time: f64 = life_time_ms / std.time.ms_per_s;
        const amp = 50;
        const y_offset = @as(i32, @intFromFloat(std.math.sin(s_time) * amp));

        rl.drawCircle(200, 200 + y_offset, 20, rl.Color.maroon);
    }
}

pub fn main() !void {
    std.debug.print("Hello World!\n", .{});
    try raylib_loop();
}
