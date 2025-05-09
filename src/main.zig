const std = @import("std");
const colisionTesting = @import("mess/sphere.zig");

const examples = enum {
    rl_unified,
    using_json,
    using_proto,
    using_comptime,
    using_fs,
};

pub fn main() !void {
    const selector: examples = .rl_unified;
    const core = @import("mess/core.zig");
    switch (selector) {
        .rl_unified => {
            std.debug.print("raylib experiments", .{});
            core.DeployInMemory();
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
    std.testing.refAllDecls(colisionTesting);
}
