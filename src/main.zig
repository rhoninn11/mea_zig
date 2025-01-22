const std = @import("std");

const examples = enum {
    phxsim,
    jtinker,
    navigation,
};

pub fn main() !void {
    const selector: examples = .navigation;
    switch (selector) {
        .phxsim => {
            const sprigy_sim = @import("simulation.zig").springy_osclation;
            std.debug.print("raylib using zig!\n", .{});
            try sprigy_sim();
        },
        .jtinker => {
            const explore_fn = @import("explore/prompt.zig").fs_explorer;
            std.debug.print("tinkering around a json!\n", .{});
            try explore_fn();
        },
        .navigation => {
            const texture_demo = @import("navi.zig").springy_osclation;
            std.debug.print("Jakies demko z kamerą i obrazkami", .{});
            try texture_demo();
        },
    }
}

test {
    std.testing.refAllDecls(@This());
}
