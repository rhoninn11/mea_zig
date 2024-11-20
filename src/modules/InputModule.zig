const rl = @import("raylib");
const rlKey = rl.KeyboardKey;

pub const EdgeType = enum {
    none,
    up,
    down,
};

pub const Signal = struct {
    const Self = @This();

    state: bool = false,
    prev_state: bool = false,

    pub fn set(self: *Self, b: bool) void {
        self.prev_state = self.state;
        self.state = b;
    }

    pub fn get(self: Self) bool {
        return self.state;
    }

    pub fn getEdge(self: Self) EdgeType {
        if (self.state and !self.prev_state) return EdgeType.up;
        if (!self.state and self.prev_state) return EdgeType.down;
        return EdgeType.none;
    }
};

pub const SignalCode = struct {
    const Self = @This();

    base: Signal = Signal{},
    positive: u8 = 'a',

    pub fn init(code: u8) Self {
        return Self{ .positive = code };
    }

    pub fn decode(self: Self) u8 {
        return switch (self.base.get()) {
            true => self.positive,
            false => 0,
        };
    }
};

const TypingMotionPhases = enum {
    released,
    first_activation,
    next_activation,
};

pub const TypingMotion = struct {
    const Self = @This();

    const _2_nd_ms: f32 = 1000;
    const _x_th_ms: f32 = 100;

    time_counter: f32 = 0,
    emited_num: u8 = 0,
    collected_num: u8 = 0,
    state: TypingMotionPhases = TypingMotionPhases.released,
    state1: TypingMotionPhases = TypingMotionPhases.released,

    fn _init(self: *Self) void {
        self.state = TypingMotionPhases.first_activation;
        self.emited_num = 1;
    }

    fn _reset(self: *Self) void {
        self.state = TypingMotionPhases.released;
        self.time_counter = 0;
        self.emited_num = 0;
        self.collected_num = 0;
    }

    pub fn _x_th_offset(self: *Self) f32 {
        const emit_num_f: f32 = @as(f32, @floatFromInt(self.emited_num - 1));
        const time_offset: f32 = Self._2_nd_ms + emit_num_f * Self._x_th_ms;
        return time_offset;
    }

    fn _process(self: *Self) void {
        if (TypingMotionPhases.next_activation == self.state) {
            const time_offset = self._x_th_offset();
            if (self.time_counter - time_offset > Self._x_th_ms) {
                self.emited_num +|= 1;
            }
        }
        if (TypingMotionPhases.first_activation == self.state) {
            if (self.time_counter > Self._2_nd_ms) {
                self.emited_num +|= 1;
                self.state = TypingMotionPhases.next_activation;
            }
        }
    }

    pub fn update(self: *Self, sig: *Signal, delta_ms: f32) void {
        switch (sig.getEdge()) {
            EdgeType.up => self._init(),
            EdgeType.down => self._reset(),
            else => {},
        }

        if (self.state != TypingMotionPhases.released) {
            self.time_counter += delta_ms;
        }

        self._process();
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
    try std.testing.expectEqual(TypingMotionPhases.first_activation, motion.state);
    try std.testing.expectEqual(1, motion.collect());

    motion.update(&sig, TypingMotion._2_nd_ms);
    try std.testing.expectEqual(TypingMotionPhases.next_activation, motion.state);
    try std.testing.expectEqual(1, motion.collect());

    motion.update(&sig, TypingMotion._x_th_ms);
    const elo = motion._x_th_offset();
    try std.testing.expectEqual(1100, elo);
    const elo2 = motion.time_counter;
    try std.testing.expectEqual(1, elo2);
    try std.testing.expectEqual(1, motion.collect());

    motion.update(&sig, TypingMotion._x_th_ms);
    try std.testing.expectEqual(1, motion.collect());

    sig.set(false);
    motion.update(&sig, TypingMotion._x_th_ms);
    try std.testing.expectEqual(0, motion.collect());
    try std.testing.expectEqual(TypingMotionPhases.released, motion.state);
}

pub const KbKey = struct {
    const Self = @This();
    motion: TypingMotion = TypingMotion{},
    hold: SignalCode,
    key: rlKey,

    pub fn init(k: rl.KeyboardKey, code: u8) KbKey {
        return KbKey{
            .key = k,
            .hold = SignalCode.init(code),
        };
    }

    pub fn check_input(self: *KbKey, delta_ms: f32) void {
        self.hold.base.set(rl.isKeyDown(self.key));
        self.motion.update(&self.hold.base, delta_ms);
    }

    pub fn collectClicks(self: *Self) u8 {
        return self.motion.collect();
    }
};

const std = @import("std");

pub fn find_input_key(char_to_find: u8) rl.KeyboardKey {
    const e_fields = @typeInfo(rl.KeyboardKey).Enum.fields;
    const match_chunk: []const u8 = &.{ '_', char_to_find };
    var result: rl.KeyboardKey = undefined;
    inline for (e_fields) |field| {
        const f_name = field.name;
        if (std.mem.indexOf(u8, f_name, match_chunk)) |idx| {
            if (idx + 2 == f_name.len) result = @field(rl.KeyboardKey, f_name);
        }
    }
    return result;
}

pub fn find_input_keys(chars_to_find: []const u8, comptime len: usize) [len]rl.KeyboardKey {
    const b = init: {
        var elo: [len]rl.KeyboardKey = undefined;
        for (chars_to_find, 0..) |char, i| {
            elo[i] = find_input_key(char);
        }
        break :init elo;
    };
    return b;
}

test "just single key" {
    const char_a = 'a';
    const result_a: rl.KeyboardKey = rl.KeyboardKey.key_a;
    const char_b = 'b';
    const result_b: rl.KeyboardKey = rl.KeyboardKey.key_b;

    var tmp = find_input_key(char_a);
    try std.testing.expect(tmp == result_a);
    tmp = find_input_key(char_b);
    try std.testing.expect(tmp == result_b);
}

test "find multiple keys" {
    const rlk = rl.KeyboardKey;
    const chars = "qwer";
    const enum_keys: []const rl.KeyboardKey = &.{ rlk.key_q, rlk.key_w, rlk.key_e, rlk.key_r };

    // const char_keys: []const u8 = "qwer";
    const found_keys: []const rl.KeyboardKey = &find_input_keys(chars, 4);

    try std.testing.expectEqualSlices(rlk, enum_keys, found_keys);
}

pub fn KbSignals(key_enums: []const rl.KeyboardKey, code_arr: []const u8, comptime n: usize) [n]KbKey {
    var holds: [n]KbKey = undefined;
    for (key_enums, code_arr, 0..) |key, code, i| {
        holds[i] = KbKey.init(key, code);
    }

    return holds;
}
