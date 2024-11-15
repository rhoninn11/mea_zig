const rl = @import("raylib");
const rlKey = rl.KeyboardKey;

pub const Hold = struct {
    state: bool,

    pub fn basic() Hold {
        return Hold{
            .state = false,
        };
    }

    pub fn set(self: *Hold, b: bool) void {
        self.state = b;
    }

    pub fn get(self: Hold) bool {
        return self.state;
    }
};

pub const InputKey = struct {
    hold: *Hold,
    key: rlKey,

    pub fn esc_hold(s: *Hold) InputKey {
        return InputKey{
            .hold = s,
            .key = rlKey.key_escape,
        };
    }
    pub fn basicKeyHold(s: *Hold, k: rl.KeyboardKey) InputKey {
        return InputKey{
            .hold = s,
            .key = k,
        };
    }

    pub fn check_input(self: *InputKey) void {
        self.hold.set(rl.isKeyDown(self.key));
    }
};

const std = @import("std");

fn name_with_underscore(comptime name: []const u8) bool {
    if (std.mem.indexOf(u8, name, "_")) {
        return true;
    }
    return false;
}

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

test "string search" {
    const result = std.mem.indexOf(u8, "jakas randomowa nazwa z ą oraz _q i alfa", " ą");
    try std.testing.expect(result != null);
}

pub fn mem_comp() void {
    const simple_text = "key_a";
    var result_1 = std.mem.split(u8, simple_text, "_");
    while (result_1.next()) |part| {
        std.debug.print("{s}\n", .{part});
    }
    std.debug.print("{s}\n", .{simple_text});

    const letters: []const u8 = "qwertyuiop";
    for (letters) |lt| {
        const sub: []const u8 = &.{ '_', lt };
        std.debug.print("{s}\n", .{sub});
    }
}
