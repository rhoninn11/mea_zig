const std = @import("std");
const colisionTesting = @import("mess/sphere.zig");

const examples = enum {
    using_rl,
    using_json,
    using_proto,
    using_comptime,
    using_fs,
    using_cli,
};

pub fn main() !void {
    const selector: examples = .using_rl;
    const core = @import("mess/core.zig");
    switch (selector) {
        .using_rl => {
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
        .using_cli => {
            @import("explore/cli.zig").program();
        },
    }
}

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(colisionTesting);
    std.testing.refAllDecls(@import("../src/explore/precompile/comptime.zig"));
}
