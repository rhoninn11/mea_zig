const rl = @import("raylib");
const rlKey = rl.KeyboardKey;

pub const Signal = struct {
    state: bool,

    pub fn basic() Signal {
        return Signal{
            .state = false,
        };
    }

    pub fn set(self: *Signal, b: bool) void {
        self.state = b;
    }

    pub fn get(self: Signal) bool {
        return self.state;
    }
};

pub const KbKey = struct {
    hold: Signal,
    key: rlKey,

    pub fn esc_hold() KbKey {
        return KbKey{
            .hold = Signal.basic(),
            .key = rlKey.key_escape,
        };
    }
    pub fn basicKeyHold(k: rl.KeyboardKey) KbKey {
        return KbKey{
            .hold = Signal.basic(),
            .key = k,
        };
    }

    pub fn check_input(self: *KbKey) void {
        self.hold.set(rl.isKeyDown(self.key));
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

pub fn KbSignals(key_enums: []const rl.KeyboardKey, comptime n: usize) [n]KbKey {
    var holds: [n]KbKey = undefined;
    for (key_enums, 0..) |key, i| {
        holds[i] = KbKey.basicKeyHold(key);
    }

    return holds;
}
