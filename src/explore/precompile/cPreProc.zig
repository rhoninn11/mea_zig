const std = @import("std");
const meta = std.meta;
const cModule = @cImport({
    @cInclude("some_c.h");
});

const zigModule = @import("plainType.zig");

// fn defaultInt() {
//     return std.meta.Int(std.builtin.Signedness.unsigned, 16);
// }

// test "my understanding of type in comptime" {
//     const T = std.builtin.Type;
//     const a = @typeInfo(T);
//     const b = comptime T{ .Int = defaultInt() };
//     comptime {
//         try std.testing.expectEqual(@TypeOf(a), @TypeOf(b));
//     }
// }

const TypeBin = struct {
    bin: std.builtin.Type,
    count: 0,
};

const TypeBIns = struct {
    bins: [8]TypeBin,
};

pub fn examineType(comptime module: type) void {
    const name = @typeName(module);
    const a = @typeInfo(module).Struct;

    std.debug.print("type name is {s} with {d} declarations\n", .{ name, a.decls.len });
    inline for (a.decls) |decl| {
        const decl_type = @TypeOf(@field(a, decl.name));
        const b = @typeName(decl_type);
        std.debug.print("name: {s}, declt type: {s}", .{ decl.name, b });
    }
    std.debug.print("\n", .{});
}

pub fn experiment() void {
    examineType(cModule);
    examineType(zigModule);
}
