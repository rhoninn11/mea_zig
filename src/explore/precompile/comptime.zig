const std = @import("std");
const meta = std.meta;
const cModule = @cImport({
    @cInclude("some_c.h");
});

const zigModule = @import("plainType.zig");

// -----
fn summaryLen(about: type) u64 {
    var counter = std.io.countingWriter(std.io.null_writer);
    writeSummary(counter.writer().any(), about);
    return counter.bytes_written;
}

fn printEnum(writer: anytype, e: std.builtin.Type.Enum) void {
    const f_n = e.fields.len;
    const d_n = e.decls.len;

    try writer.print("\t{d} - fields\n", .{f_n});
    try writer.print("\t{d} - decls\n", .{d_n});
}

const Type = std.builtin.Type;

const Tname = struct {
    t: Type,
    name: []const u8,
};

fn stringDecl_manual(of: type, name: []const u8) Tname {
    var declKind = @typeInfo(@TypeOf(@field(of, name)));
    if (declKind != .Fn) declKind = @typeInfo(@field(of, name));

    return Tname{
        .t = declKind,
        .name = switch (declKind) {
            .Fn => "Fn",
            .Enum => "Enum",
            .Struct => "Struct",
            else => "other",
        },
    };
}

// print declaration of struct to writer
fn printDeclaration(writer: anytype, comptime of: type) void {
    const as_struct = @typeInfo(of).Struct;
    const decle_num = as_struct.decls.len;

    try writer.print("\t{d} declarations:\n", .{decle_num});

    for (as_struct.decls) |decl| {
        const name = decl.name;
        const kind = stringDecl_manual(of, name);
        writer.print("{s: <10} - {s}\n", .{ decl.name, kind.name }) catch unreachable;
        if (kind.t == .Enum) {
            const enumeration = @typeInfo(@field(of, name)).Enum;
            // _ = enumeration;
            printEnum(writer, enumeration);
        }
    }
}

fn writeSummary(writer: anytype, about: type) void {
    const name = @typeName(about);
    const as_struct = @typeInfo(about).Struct;
    const f_n = as_struct.fields.len;

    writer.print("+++ Type - {s}:\n", .{name}) catch unreachable;
    writer.print("\t{d} fields:\n", .{f_n}) catch unreachable;
    for (as_struct.fields) |field| {
        writer.print("\t{s},", .{field.name}) catch unreachable;
    }
    if (f_n != 0) writer.print("\n", .{}) catch unreachable;

    printDeclaration(writer, about);
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

pub fn examineType(comptime module: type) void {
    const module_summary = comptime typeSummary(module);
    std.debug.print("{s}\n", .{module_summary});

    //
    //  Ale domyślny cel jest taki, żeby znaleźć wszystkie enumy i stworzyć dla nich funkcję,
    //  która będzie zwracała nazwy wszystkich pól jako stringi, tak żeby w runtimeie można było
    //  potem je odczytać
    //  istniej nawet sznasa na jej szybkie wykorzystanie w funkcji oznaczonej jako _manual

}

pub fn comptimeExperiment() void {
    // examineType(cModule);
    // examineType(zigModule);
    examineType(zigModule);
}
