const std = @import("std");
const meta = std.meta;
const cModule = @cImport({
    @cInclude("some_c.h");
});

const zigModule = @import("plainType.zig");

const TypeBin = struct {
    bin: std.builtin.Type,
    count: 0,
};

const TypeBIns = struct {
    bins: [8]TypeBin,
};

fn summaryLen(about: type) u64 {
    var counter = std.io.countingWriter(std.io.null_writer);
    writeSummary(counter.writer().any(), about);
    return counter.bytes_written;
}

fn printEnum(writer: anytype, e: std.builtin.Type.Enum) void {
    const prefix = "\t\t";
    const f_n = e.fields.len;
    const d_n = e.decls.len;

    writer.print("{s}\t{d} - fields", .{ prefix, f_n });
    writer.print("{s}\t{d} - decls", .{ prefix, d_n });
}

fn writeSummary(writer: anytype, about: type) void {
    const name = @typeName(about);
    const as_struct = @typeInfo(about).Struct;
    const f_n = as_struct.fields.len;
    const d_n = as_struct.decls.len;
    writer.print("+++ Type - {s}:\n", .{name}) catch unreachable;
    writer.print("\t{d} fields:\n", .{f_n}) catch unreachable;
    for (as_struct.fields) |field| {
        writer.print("\t{s},", .{field.name}) catch unreachable;
    }
    if (f_n != 0) writer.print("\n", .{}) catch unreachable;

    writer.print("\t{d} declarations:\n", .{d_n}) catch unreachable;
    for (as_struct.decls) |decl| {
        var declKind = @typeInfo(@TypeOf(@field(about, decl.name)));
        if (declKind != .Fn) declKind = @typeInfo(@field(about, decl.name));

        // @compileLog(declType);
        const kind: []const u8 = switch (declKind) {
            .Fn => "Fn",
            .Enum => "Enum",
            .Struct => "Struct",
            else => "other",
        };
        if (declKind == .Enum) {}

        writer.print("\t\t{s: <10} - {s}\n", .{ decl.name, kind }) catch unreachable;
    }
    writer.print("\n", .{}) catch unreachable;
}

fn typeSummary(comptime module: type) *const [summaryLen(module):0]u8 {
    const len = comptime summaryLen(module);
    comptime {
        var summary_buff: [len:0]u8 = undefined;
        var fbs = std.io.fixedBufferStream(&summary_buff);
        var wrtr = fbs.writer();
        writeSummary(wrtr.any(), module);
        const final = summary_buff;
        return &final;
    }
}

pub fn experiment() void {
    // examineType(cModule);
    // examineType(zigModule);
    examineType(zigModule);
}

pub fn examineType(comptime module: type) void {
    const module_summary = comptime typeSummary(module);
    std.debug.print("{s}\n", .{module_summary});

    //
    //  Ale domyślny cel jest taki, żeby znaleźć wszystkie enumy i stworzyć dla nich funkcję,
    //  która będzie zwracała nazwy wszystkich pól jako stringi, tak żeby w runtimeie można było
    //  potem je odczytać

}
