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

pub fn find_input_keys() comptime_int {
    const k_n = blk: {
        const all_keys = @typeInfo(rl.KeyboardKey).Enum.fields;

        var input_kyes_n = 0;
        for (all_keys) |key_name| {
            // if (name_with_underscore(key_name.name)) {
            //     input_kyes_n += 1;
            //  }
            if (key_name.name.len > 0) {
                input_kyes_n += 1;
            }
        }

        break :blk input_kyes_n;
    };
    return k_n;
}
