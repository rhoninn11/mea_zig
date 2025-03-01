const std = @import("std");

const examples = enum {
    rl_inertia,
    rl_navigation,
    rl_unified,
    using_json,
    using_proto,
    using_comptime,
    using_fs,
};

pub fn main() !void {
    const selector: examples = .using_comptime;
    const core = @import("mess/core.zig");
    switch (selector) {
        .rl_inertia => {
            const rl_springs = @import("SpringSim.zig").program;
            std.debug.print("raylib using zig!\n", .{});
            core.DeployInMemory(rl_springs);
        },
        .rl_navigation => {
            const rl_devel = @import("Navig.zig").program;
            std.debug.print("raylib experiments", .{});
            core.DeployInMemory(rl_devel);
        },
        .rl_unified => {
            std.debug.print("raylib experiments", .{});
            core.DeployInMemory(core.windowed_program);
        },
        .using_json => {
            const explore_fn = @import("explore/prompt.zig").fs_explorer;
            try explore_fn();
        },
        .using_proto => {
            const pt = @import("explore/protobuf.zig");
            try pt.protobufTest();
        },
        .using_comptime => {
            const cpp_xd = @import("explore/precompile/comptime.zig");
            cpp_xd.comptimeExperiment();
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
