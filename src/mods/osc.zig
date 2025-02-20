const std = @import("std");
const math = @import("core/math.zig");
const vf2 = math.fv2;

pub const Osc = struct {
    amp: f32 = 20,
    phase: f32 = 0,

    pub fn update(self: *Osc, time_delta_ms: f32) void {
        const delta_s = time_delta_ms / std.time.ms_per_s;
        self.phase += delta_s * std.math.pi * 2;
    }

    pub fn smple2D(self: Osc) vf2 {
        const x: f32 = std.math.cos(self.phase) * self.amp;
        const y: f32 = std.math.sin(self.phase) * self.amp;
        return vf2{ x, y };
    }

    pub fn createN(comptime n: usize) [n]Osc {
        const result: [n]Osc = .{Osc{}} ** n;
        return result;
    }
};
