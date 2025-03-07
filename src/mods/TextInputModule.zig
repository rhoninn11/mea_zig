const std = @import("std");
const Allocator = std.mem.Allocator;

const rlui = @import("raygui");
const rl = @import("raylib");

const InputModule = @import("input.zig");
const KbKey = InputModule.KbKey;

const TimeLock = @import("time.zig").TimeLock;

const TextBuffor = struct {
    const Self = @This();
    buffor: [:0]u8,
    char_num: u16,
    line_num: u16,

    pub fn init(arena: Allocator) !Self {
        const buf = try arena.allocSentinel(u8, 1000, 0);
        @memset(buf, 0);
        return TextBuffor{
            .buffor = buf,
            .char_num = 0,
            .line_num = 0,
        };
    }
    pub fn addNewLine(self: *Self) void {
        self.buffor[self.char_num] = '\n';
        self.char_num += 1;
        self.line_num += 1;
    }

    pub fn addCharacter(self: *Self, char: u8) void {
        self.buffor[self.char_num] = char;
        self.char_num += 1;

        if ((self.char_num - self.line_num) % 20 == 0) self.addNewLine();
    }

    pub fn cStr(self: *Self) [*:0]u8 {
        return self.buffor.ptr;
    }
};
