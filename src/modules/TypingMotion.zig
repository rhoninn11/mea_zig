const Signal = @import("InputModule.zig").Signal;
const EdgeType = Signal.EdgeType;
const std = @import("std");

const CollectMode = enum(u32) { released, first_activation, next_activation, elo };

pub const TypingMotion = struct {
    const Self = @This();

    const _2_nd_ms: f32 = 1000;
    const _x_th_ms: f32 = 100;

    time_counter: f32 = 0,
    emited_num: u8 = 0,
    collected_num: u8 = 0,
    state: CollectMode = CollectMode.released,

    fn _init(self: *Self) CollectMode {
        self.emited_num = 1;
        return CollectMode.first_activation;
    }

    fn _reset(self: *Self) CollectMode {
        self.time_counter = 0;
        self.emited_num = 0;
        self.collected_num = 0;
        return CollectMode.released;
    }

    pub fn _x_th_offset(self: *Self) f32 {
        const emit_num_f: f32 = @as(f32, @floatFromInt(self.emited_num - 2));
        const time_offset: f32 = Self._2_nd_ms + emit_num_f * Self._x_th_ms;
        return time_offset;
    }

    fn _process(self: *Self) CollectMode {
        var next_state = self.state;
        switch (self.state) {
            CollectMode.first_activation => {
                if (self.time_counter > Self._2_nd_ms) {
                    self.emited_num +|= 1;
                    next_state = CollectMode.next_activation;
                }
            },
            CollectMode.next_activation => {
                const elapsed_ms = self.time_counter - self._x_th_offset();
                if (elapsed_ms > Self._x_th_ms) {
                    self.emited_num +|= 1;
                }
            },
            else => unreachable,
        }
        return next_state;
    }

    pub fn update(self: *Self, sig: *Signal, delta_ms: f32) void {
        const edge_state_change = switch (sig.getEdge()) {
            EdgeType.up => self._init(),
            EdgeType.down => self._reset(),
            else => self.state,
        };
        self.state = edge_state_change;
        if (self.state == CollectMode.released)
            return;

        self.time_counter += delta_ms;

        const post_proc_state = self._process();
        self.state = post_proc_state;
    }

    pub fn collect(self: *Self) u8 {
        const delta: u8 = self.emited_num - self.collected_num;
        self.collected_num = self.emited_num;
        return delta;
    }
};

test "typing motion test" {
    var motion = TypingMotion{};
    var sig = Signal{};

    sig.set(true);
    motion.update(&sig, 10);
    try std.testing.expectEqual(CollectMode.first_activation, motion.state);
    try std.testing.expectEqual(1, motion.collect());

    sig.set(true);
    motion.update(&sig, TypingMotion._2_nd_ms);
    try std.testing.expectEqual(CollectMode.next_activation, motion.state);
    try std.testing.expectEqual(1, motion.collect());

    sig.set(true);
    motion.update(&sig, TypingMotion._x_th_ms);
    try std.testing.expectEqual(1, motion.collect());

    sig.set(true);
    motion.update(&sig, TypingMotion._x_th_ms);
    try std.testing.expectEqual(1, motion.collect());

    sig.set(false);
    motion.update(&sig, TypingMotion._x_th_ms);
    try std.testing.expectEqual(0, motion.collect());
    try std.testing.expectEqual(CollectMode.released, motion.state);
}
