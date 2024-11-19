const std = @import("std");
const Allocator = std.mem.Allocator;

const rlui = @import("raygui");
const rl = @import("raylib");

const InputModule = @import("InputModule.zig");
const KbKey = InputModule.KbKey;

const TimeLock = @import("../_time.zig").TimeLock;

pub const AlfanumericBufforEditor = struct {
    const Self = @This();

    rate_limiter: TimeLock = TimeLock{},
    buffor: [:0]u8,
    char_num: u16,
    line_num: u16,

    pub fn spawn(arena: Allocator) !Self {
        const buffor = try arena.allocSentinel(u8, 1000, 0);
        buffor[0] = 0;
        return AlfanumericBufforEditor{
            .buffor = buffor,
            .char_num = 0,
            .line_num = 0,
        };
    }

    fn addCharacter(self: *Self, char: u8) void {
        self.buffor[self.char_num] = char;
        self.char_num += 1;

        if ((self.char_num - self.line_num) % 20 == 0) {
            self.buffor[self.char_num] = '\n';
            self.char_num += 1;
            self.line_num += 1;
        }
        self.buffor[self.char_num] = 0;
    }

    pub fn collectInput(self: *Self, keys: []KbKey, dt_ms: f32) void {
        if (self.rate_limiter.lockPass(dt_ms) == false)
            return;

        over_keys: for (keys) |key| {
            if (key.hold.base.get()) {
                self.addCharacter(key.hold.decode());
                self.rate_limiter.arm();
                break :over_keys;
            }
        }
    }

    pub fn cStr(self: *Self) [*:0]u8 {
        return self.buffor.ptr;
    }
};
