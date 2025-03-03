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
    // const d_n = enumInfo.decls.len;

    writer.print("\t{d} - fields\n", .{f_n}) catch unreachable;
    for (enumInfo.fields) |field| {
        writer.print(" - {s: <10} - {d}\n", .{ field.name, field.value }) catch unreachable;
    }
    writer.print("\n", .{}) catch unreachable;
}

test "runtime enum field names" {
    const TestEnum = zigModule.Wyliczanka;
    const TestUnion = zigModule.Bunch;
    const a = TestEnum.due;
    const b = TestEnum.rike;
    const c = TestUnion{ .of_one = b };

    try std.testing.expectEqualStrings("due", @tagName(a));
    try std.testing.expectEqualStrings("rike", @tagName(b));
    try std.testing.expectEqualStrings("of_one", @tagName(c));
}

const Type = std.builtin.Type;

const Kind = struct {
    base_type: type,
    base_name: []const u8,
    lower_type: Type,
    lower_name: []const u8,

    fn init(about: type) Kind {
        const type_info = @typeInfo(about);
        return Kind{
            .base_type = about,
            .base_name = @typeName(about),
            .lower_type = type_info,
            .lower_name = @tagName(type_info),
        };
    }

    fn field(me: Kind, name: []const u8) Kind {
        const field_value = @field(me.base_type, name);
        const field_type = @TypeOf(field_value);

        const clean_type: type = switch (@typeInfo(field_type)) {
            .Fn => field_type,
            else => field_value,
        };

        return Kind.init(clean_type);
    }
};

// print declaration of struct to writer
fn printDeclaration(writer: anytype, comptime of: type) void {
    var top_kind = Kind.init(of);
    const as_struct = top_kind.lower_type.Struct;
    const decle_num = as_struct.decls.len;

    try writer.print("\t{d} declarations:\n", .{decle_num});

    for (as_struct.decls) |decl| {
        const member = top_kind.field(decl.name);
        writer.print("{s: <16} + {s: >7} -  {s}\n", .{ decl.name, member.lower_name, member.base_name }) catch unreachable;
        if (member.lower_type == .Enum) {
            printEnum(writer, member);
        }
        if (member.lower_type == .Union) {
            writer.print("+++\n", .{}) catch unreachable;
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
