const std = @import("std");
const rl = @import("raylib");
const TypingMotion = @import("TypingMotion.zig").TypingMotion;

const Module = @This();

pub const Signal = struct {
    pub const EdgeType = enum {
        none,
        up,
        down,
    };

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

pub const KbKey = struct {
    const Self = @This();
    motion: TypingMotion = TypingMotion{},
    hold: SignalCode,
    key: rl.KeyboardKey,

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

pub fn extractSignals(comptime n: usize, kb_keys: *[n]KbKey) [n]*Signal {
    var sig_arr: [n]*Signal = undefined;
    for (kb_keys, 0..) |*kb, i| sig_arr[i] = &kb.hold.base;
    return sig_arr;
}

pub const Delay = struct {
    const Self = @This();

    to_track: *Signal,
    internal: Signal = Signal{},
    ms_delay: f32 = 500,
    delay_counter: f32 = 0,
    pub fn update(self: *Self, ms_delta: f32) void {
        self.delay_counter = switch (self.to_track.get()) {
            true => self.delay_counter + ms_delta,
            false => 0,
        };

        if (self.delay_counter > self.ms_delay) self.internal.set(true);
    }

    pub fn get(self: Self) bool {
        return self.internal.get();
    }

    pub fn sigRef(self: *Self) *Signal {
        return &self.internal;
    }
};

// -----------------------------------

pub fn obtain_keys(comptime n: usize, comptime letters: *const [n:0]u8) [n]KbKey {
    const key_n = letters.len;
    const keys = charKeyArray(letters, key_n);
    return KbSignals(&keys, letters, key_n);
}

pub fn KbSignals(key_enums: []const rl.KeyboardKey, code_arr: []const u8, comptime n: usize) [n]KbKey {
    var holds: [n]KbKey = undefined;
    for (key_enums, code_arr, 0..) |key, code, i| {
        holds[i] = KbKey.init(key, code);
    }

    return holds;
}
pub fn charKeyArray(chars: []const u8, comptime len: usize) [len]rl.KeyboardKey {
    return rl_keys: {
        var char_key_arr: [len]rl.KeyboardKey = undefined;
        for (chars, 0..) |char, i| {
            char_key_arr[i] = charKey(char);
        }
        break :rl_keys char_key_arr;
    };
}

pub fn charKey(char: u8) rl.KeyboardKey {
    const e_fields = @typeInfo(rl.KeyboardKey).Enum.fields;
    const match_chunk: []const u8 = &.{ '_', char };
    var result: rl.KeyboardKey = undefined;
    inline for (e_fields) |field| {
        const f_name = field.name;
        if (std.mem.indexOf(u8, f_name, match_chunk)) |idx| {
            if (idx + 2 == f_name.len) result = @field(rl.KeyboardKey, f_name);
        }
    }
    return result;
}

test "comptime find keys" {
    const char_a = 'a';
    const result_a: rl.KeyboardKey = rl.KeyboardKey.key_a;
    const char_b = 'b';
    const result_b: rl.KeyboardKey = rl.KeyboardKey.key_b;

    var tmp = charKey(char_a);
    try std.testing.expect(tmp == result_a);
    tmp = charKey(char_b);
    try std.testing.expect(tmp == result_b);
}

test "find multiple keys" {
    const rlk = rl.KeyboardKey;
    const chars = "qwer";
    const enum_keys: []const rl.KeyboardKey = &.{ rlk.key_q, rlk.key_w, rlk.key_e, rlk.key_r };

    // const char_keys: []const u8 = "qwer";
    const found_keys: []const rl.KeyboardKey = &charKeyArray(chars, 4);

    try std.testing.expectEqualSlices(rlk, enum_keys, found_keys);
}

test "comptime len calc" {
    const action_key: []const u8 = "qwert";
    const action_len = action_key.len;
    const mapping = Module.charKeyArray(action_key, action_len);
    try std.testing.expect(mapping.len == action_len);
}

// -----------------

const math = @import("core/math.zig");
const i2f = math.i2f;
pub fn sample_mouse() math.vf2 {
    const mx = rl.getMouseX();
    const my = rl.getMouseY();

    const point_by_mouse = math.vf2{ i2f(mx), i2f(my) };
    return point_by_mouse;
}
