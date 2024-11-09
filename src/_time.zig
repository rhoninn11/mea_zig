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
