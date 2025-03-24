const std = @import("std");
const Inst = std.time.Instant;
const Timer = std.time.Timer;

pub const Timeline = struct {
    last_lap: f32 = 0,
    timer: Timer,

    pub fn init() !Timeline {
        return Timeline{
            .timer = try Timer.start(),
        };
    }

    pub fn tickMs(self: *Timeline) f32 {
        self.last_lap = @floatFromInt(self.timer.lap());
        self.last_lap /= std.time.ns_per_ms;
        return self.last_lap;
    }
};

pub const TimeLock = struct {
    const Self = @This();

    lock_time_ms: f32 = 100,
    time_counter: f32 = 0,

    pub fn arm(self: *Self) void {
        self.time_counter = self.lock_time_ms;
    }

    pub fn lockPass(self: *Self, delta_ms: f32) bool {
        const updated = self.time_counter - delta_ms;
        self.time_counter = if (updated <= 0) 0 else updated;
        return self.time_counter == 0;
    }
};
