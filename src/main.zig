const std = @import("std");

const examples = enum {
    rl_inertia,
    rl_navigation,
    rl_unified,
    using_json,
    using_proto,
    using_cheader,
    using_fs,
};

pub fn main() !void {
<<<<<<< HEAD
    const selector: examples = .rl_unified;
    const AppCore = @import("mess/core.zig");
=======
    const selector: examples = .using_fs;
    const AppCore = @import("core.zig");
>>>>>>> origin
    switch (selector) {
        .rl_inertia => {
            const rl_springs = @import("SpringSim.zig").program;
            std.debug.print("raylib using zig!\n", .{});
            AppCore.DeployInMemory(rl_springs);
        },
        .rl_navigation => {
            const rl_devel = @import("Navig.zig").program;
            std.debug.print("raylib experiments", .{});
            AppCore.DeployInMemory(rl_devel);
        },
        .rl_unified => {
            std.debug.print("raylib experiments", .{});
            AppCore.DeployInMemory(AppCore.windowed_program);
        },
        .using_json => {
            const explore_fn = @import("explore/prompt.zig").fs_explorer;
            try explore_fn();
        },
        .using_proto => {
            const pt = @import("explore/protobuf.zig");
            try pt.protobufTest();
        },
        .using_cheader => {
            const cpp_xd = @import("explore/precompile/cPreProc.zig");
            cpp_xd.experiment();
        },
        .using_fs => {
            const fs_exp = @import("explore/filesystem.zig");
            try fs_exp.fs_explorer();
        },
    }
}

test {
    std.testing.refAllDecls(@This());
}
