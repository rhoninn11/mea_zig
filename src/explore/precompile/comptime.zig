const std = @import("std");
const meta = std.meta;
const cModule = @cImport({
    @cInclude("some_c.h");
});

const zigModule = @import("testnaemspace.zig");

// -----
fn summaryLen(about: type) u64 {
    var counter = std.io.countingWriter(std.io.null_writer);
    writeSummary(counter.writer().any(), about);
    return counter.bytes_written;
}

fn printEnum(writer: anytype, e: Kind) void {
    const enumInfo = e.lower_type.Enum;
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
    base_type: type,
    lower_type: Type,

    fn init(about: type) Kind {
        return Kind{
            .base_type = about,
            .lower_type = @typeInfo(about),
            .type_name = @typeName(about),
        };
    }

    fn field(me: *Kind, name: []const u8) Kind {
        // return type exepte fn resides under that field
        const it_was_not_an_fn = @field(me.base_type, name);

        const fnType = @TypeOf(it_was_not_an_fn);
        // for other types then Fn type data is lost
        const elo: type = switch (@typeInfo(fnType)) {
            .Fn => fnType,
            else => Kind.init(it_was_not_an_fn),
        };

        return Kind.init(elo);
    }
};

fn stringDecl_manual(of: Kind) []const u8 {
    return switch (of.lower_type) {
        .Fn => "Fn",
        .Enum => "Enum",
        .Struct => "Struct",
        else => "other",
    };
}

test "for type travelsal" {
    try std.testing.expect(@TypeOf(Type) == .Union);
}

fn grabLowerName(of: Kind) []const u8 {
    // const val: Type = of.type_info;

    const lower_level: Kind = Kind.init(Type);
    const lower_type = lower_level.lower_type;
    if (lower_type == .Union) {
        const as_union = lower_type.Union;
        for (as_union.decls) |decl| {
            const result_name = decl.name;
            const lower_kind = lower_level.field(decl.name);
            if (of.lower_type == lower_kind) {
                @compileLog(result_name);
            }
        }
    }

    return "not fully implemented";
}

fn isEnum(kind: Kind) bool {
    return kind.lower_type == .Enum;
}

// print declaration of struct to writer
fn printDeclaration(writer: anytype, comptime of: type) void {
    var top_kind = Kind.init(of);
    const as_struct = top_kind.lower_type.Struct;
    const decle_num = as_struct.decls.len;

    try writer.print("\t{d} declarations:\n", .{decle_num});

    for (as_struct.decls) |decl| {
        const member = top_kind.field(decl.name);
        // const sub_kind = Kind.init();
        const lower_name = stringDecl_manual(member);
        // const kind_name = stringDecl_manual(@field(lhs: anytype, comptime field_name: []const u8));

        writer.print("{s: <16} + {s: >7} -  {s}\n", .{ decl.name, lower_name, member.type_name }) catch unreachable;
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

    writer.print("+++ looking at - {s}:\n", .{name}) catch unreachable;
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
