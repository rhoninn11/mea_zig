const std = @import("std");
const Inst = std.time.Instant;

pub const Timeline = struct {
    then: Inst,

    pub fn basic() !Timeline {
        const timespace = try Inst.now();
        return Timeline{
            .then = timespace,
        };
    }

    pub fn messureFrom(self: *Timeline) !void {
        self.then = try Inst.now();
    }

    pub fn elapsedInfo(self: Timeline) !f64 {
        const now = try Inst.now();
        const elapsed_ns: f64 = @floatFromInt(now.since(self.then));
        const elapsed_ms = elapsed_ns / std.time.ns_per_ms;
        return elapsed_ms;
    }

    pub fn tickMs(self: *Timeline) !f32 {
        const time_delta_us = try self.elapsedInfo();
        try self.messureFrom();
        return @floatCast(time_delta_us);
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
