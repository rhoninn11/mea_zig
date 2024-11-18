const std = @import("std");
const Allocator = std.mem.Allocator;

const rlui = @import("raygui");
const rl = @import("raylib");

const InputModule = @import("InputModule.zig");
const KbKey = InputModule.KbKey;

const Self = @This();

pub const AlfanumericIn = struct {
    pub fn clickSniffer(keys: []KbKey) void {
        for (keys) |key| {
            if (key.hold.base.get()) {
                std.debug.print("key {c} clicked\n", .{key.hold.decode()});
            }
        }
    }
};

const VF2 = @Vector(2, f32);
pub const TextInputTest = struct {
    size: VF2 = .{ 300, 100 },
    pos: VF2 = .{ 400, 300 },
    text_memory: [:0]u8,

    pub fn init(arena: Allocator) !TextInputTest {
        var buffer = try arena.allocSentinel(u8, 64, 0);
        @memcpy(buffer[0..24], "cokolwiek by tu nie\nbylo");
        return TextInputTest{ .text_memory = buffer };
    }

    pub fn draw(self: TextInputTest) void {
        const rect = rl.Rectangle{
            .width = self.size[0],
            .height = self.size[1],
            .x = self.pos[0],
            .y = self.pos[1],
        };
        _ = rlui.guiTextBox(rect, self.text_memory.ptr, 82, false);
    }
};
