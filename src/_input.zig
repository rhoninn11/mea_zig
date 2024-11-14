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

pub fn find_input_keys() []rl.KeyboardKey {
    const chars: []const u8 = "qwer";
    const keys_fields = @typeInfo(rl.KeyboardKey).Enum.fields;
    var rl_keys: [4]rl.KeyboardKey = undefined;
    for (chars) |char| {
        var num: usize = 0;
        const to_search: []const u8 = &.{ '_', char };
        inline for (keys_fields) |field| {
            if (std.mem.indexOf(u8, field.name, to_search)) |_| {
                // this field name needs to be extracted as rl.KeyboardKey
                const elo = @field(rl.KeyboardKey, field.name);
                rl_keys[num] = elo;
            }
        }
        num += 1;
    }

    return &rl_keys;
}

test "find proper keys" {
    const rlk = rl.KeyboardKey;
    const enum_keys: []const rl.KeyboardKey = &.{ rlk.key_q, rlk.key_w, rlk.key_e, rlk.key_r };

    // const char_keys: []const u8 = "qwer";
    const found_keys = find_input_keys();

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
