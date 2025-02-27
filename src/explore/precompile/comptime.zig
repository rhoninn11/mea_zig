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
    const modul_as_struct = @typeInfo(module).Struct;

    const fields = modul_as_struct.fields;
    const decls = modul_as_struct.decls;
    const f_n = fields.len;
    const d_n = decls.len;

    std.debug.print("typeOf( {s} ):\n\tdecls - {d}\n\tfields - {d}\n", .{ name, d_n, f_n });
    // for (modul_as_struct.decls) |decl| {
    //     const decl_type = @TypeOf(@field(a, decl.name));
    //     const b = @typeName(decl_type);
    //     std.debug.print("name: {s}, declt type: {s}", .{ decl.name, b });
    // }
    std.debug.print("\n", .{});
}

// fn putIn(comptime slice: []u8, comptime text: []const u8) comptime []u8 {
//     // hmmm
// }

fn slicesAtComptime() void {
    comptime var mesg_buff = [_]u8{'0'} ** 1024;
    comptime var mesg_slice = mesg_buff[0..mesg_buff.len];

    const name = "miś jogi";
    const d_n = 1;
    const f_n = 2;
    const comptime_info = std.fmt.comptimePrint("typeOf( {s} ):\n", .{name});
    // how to make this block one comptime liner? może to musi być inline??
    const len = comptime_info.len;
    @memcpy(mesg_slice[0..len], comptime_info);
    mesg_slice = mesg_slice[0..];

    _ = d_n;
    _ = f_n;
    // const comptime_info = std.fmt.comptimePrint("\t {d} Fields:\n", .{f_n});
    // const comptime_info = std.fmt.comptimePrint("\t {d} Declarations:\n", .{d_n});

    std.debug.print("{s}\n", .{comptime_info});
}

pub fn experiment() void {
    // examineType(cModule);
    // examineType(zigModule);
    slicesAtComptime();
}
