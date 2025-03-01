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

fn printEnum(writer: anytype, e: Kind) void {
    const enumInfo = e.type_info.Enum;
    const f_n = enumInfo.fields.len;
    const d_n = enumInfo.decls.len;

    try writer.print("\t{d} - fields\n", .{f_n});
    for (e.fields) |field| {
        try writer.print("{s} - {d}, ", .{ field.name, field.value });
    }
    try writer.print("\n", .{});

    try writer.print("\t{d} - decls\n", .{d_n});
    @compileLog(@typeName(@TypeOf(e)));
}

const Type = std.builtin.Type;

const Kind = struct {
    type_name: []const u8,
    just_type: type,
    type_info: Type,

    fn init(about: type) Kind {
        return Kind{
            .just_type = about,
            .type_info = @typeInfo(about),
            .type_name = @typeName(about),
        };
    }

    fn field(me: *Kind, name: []const u8) Kind {
        const my_field = @field(me.just_type, name);
        // const typeInfo = @typeInfo(my_field);
        // for type will be .Union, for fn is compile error xD

        // return type exepte fn resides under that field
        // so if we further investigate, that type of variable is type not fn
        // we can init Kind from it
        // the way to check type is to get builtin.Type
        // but if we spot that is a function we need extract its type

        const fnType = @TypeOf(my_field);
        return switch (@typeInfo(fnType)) {
            .Fn => Kind.init(fnType),
            // for other types then Fn type data is lost
            else => Kind.init(my_field),
        };
    }
};

fn stringDecl_manual(of: Kind) []const u8 {
    @compileLog(of);
    return switch (of.type_info) {
        .Fn => "Fn",
        .Enum => "Enum",
        .Struct => "Struct",
        else => "other",
    };
}

fn isEnum(kind: Kind) bool {
    return kind.type_info == .Enum;
}

// print declaration of struct to writer
fn printDeclaration(writer: anytype, comptime of: type) void {
    var top_kind = Kind.init(of);
    const as_struct = top_kind.type_info.Struct;
    const decle_num = as_struct.decls.len;

    try writer.print("\t{d} declarations:\n", .{decle_num});

    for (as_struct.decls) |decl| {
        const sub_type = top_kind.field(decl.name);
        // const sub_kind = Kind.init();
        // const kind_name = stringDecl_manual(@field(lhs: anytype, comptime field_name: []const u8));

        writer.print("{s: <10} - {s}\n", .{ decl.name, sub_type.type_name }) catch unreachable;
        if (isEnum(top_kind)) {
            // @compileLog(kind.type_name);
            // printEnum(writer, kind);
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
