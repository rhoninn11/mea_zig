const std = @import("std");

const examples = enum {
    phxsim,
    jtinker,
    navigation,
    prototest,
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
            std.debug.print("Na razie tutaj łatwiej było opracować zamykanie okna" ++
                "Ale w tutaj przećwiczone zostaną jeszcze eksperymenty z teksturami", .{});
            try texture_demo();
        },
        .prototest => {
            const pt = @import("explore/protobuf.zig");
            pt.protobufTest();
        },
    }
}

test {
    std.testing.refAllDecls(@This());
}
