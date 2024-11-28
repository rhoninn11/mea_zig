const std = @import("std");

pub const Osc = struct {
    amp: f32 = 20,
    phase: f32 = 0,

    pub fn update(self: *Osc, time_delta_ms: f32) void {
        const delta_s = time_delta_ms / std.time.ms_per_s;
        self.phase += delta_s * std.math.pi * 2;
    }
};
