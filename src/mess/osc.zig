const std = @import("std");
const math = @import("math.zig");
const fvec2 = math.fv2;

pub const Osc = struct {
    amp: f32 = 1,
    phase: f32 = 0,
    freq: f32 = 1,

    pub inline fn update(self: *Osc, time_delta_ms: f32) void {
        const delta_s = time_delta_ms * self.freq / std.time.ms_per_s;
        self.phase += delta_s * std.math.pi * 2;
    }

    pub inline fn sample2D(self: Osc) fvec2 {
        const x: f32 = std.math.cos(self.phase) * self.amp;
        const y: f32 = std.math.sin(self.phase) * self.amp;
        return fvec2{ x, y };
    }

    pub inline fn sample(self: Osc) f32 {
        return std.math.cos(self.phase) * self.amp;
    }
    pub fn createN(comptime n: usize) [n]Osc {
        const result: [n]Osc = .{Osc{}} ** n;
        return result;
    }

    pub fn log(self: *Self) void {
        std.log.debug(
            "Phase: {d}, Amp: {d}, Freq {d}\n",
            .{ self.phase, self.amp, self.freq },
        );
    }
};

const Self = Osc;
