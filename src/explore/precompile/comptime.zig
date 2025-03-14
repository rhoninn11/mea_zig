const std = @import("std");
const meta = std.meta;
const cModule = @cImport({
    @cInclude("webgpu.h");
});

const zigModule = @import("testnaemspace.zig");
const generatedProtobuffer = @import("../../gen/comfy.pb.zig");

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
    writer.print(" (f {d})\n", .{f_n}) catch unreachable;

    for (enumInfo.fields) |field|
        writer.print(" - {d} - {s: <10}", .{ field.value, field.name }) catch unreachable;
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
    lower_type: Type,
    base_name: []const u8,
    lower_name: []const u8,

    fn of(basic: type) Kind {
        const type_info = @typeInfo(basic);
        return Kind{
            .base_type = basic,
            .lower_type = type_info,
            .base_name = @typeName(basic),
            .lower_name = @tagName(type_info),
        };
    }

    fn fieldOf(basic: type, field_name: []const u8) ?Kind {
        const field_value = @field(basic, field_name);
        const field_type = @TypeOf(field_value);

        // Int and some other will cause compilation errorerror
        // @compileLog(field_type);
        // @compileLog(name)
        const clean_type: type = switch (@typeInfo(field_type)) {
            .Fn => field_type,
            .Int => field_type,
            .Pointer => field_type,
            else => field_value,
            .Optional => {
                return null;
            },
        };

        return Kind.of(clean_type);
    }
};

fn prefixFilterPass(name: []const u8, exclude_starts: []const []const u8) ?void {
    for (exclude_starts) |needle|
        if (std.mem.startsWith(u8, name, needle)) return null;
}

fn printType(writer: anytype) void {
    const u = @typeInfo(std.builtin.Type).Union;
    writer.print("f{d} d{d}\n", .{ u.fields.len, u.decls.len }) catch unreachable;
}

// print declaration of struct to writer
fn printDeclaration(writer: anytype, comptime basic: type) void {
    const top_kind = Kind.of(basic);
    const as_struct = top_kind.lower_type.Struct;

    const prefs: []const []const u8 = &.{ "__", "_", "offsetof", "WGPU_" };
    for (as_struct.decls) |decl| {
        prefixFilterPass(decl.name, prefs) orelse continue;
        const member = Kind.fieldOf(basic, decl.name) orelse continue;

        writer.print("\n{s: <16} | {s: >7} |  {s}", .{ decl.name, member.lower_name, member.base_name }) catch unreachable;
        switch (member.lower_type) {
            // .Enum => printEnum(writer, member),
            .Union => writer.print("+++\n", .{}) catch unreachable,
            else => {},
        }
    }
}

fn isCEnumName(name: []const u8) bool {
    return std.mem.startsWith(u8, name, "enum_");
}

fn countDeclWithPrefix(s: std.builtin.Type.Struct, prefix: []const u8) u32 {
    return comptime blk: {
        var count: u32 = 0;
        for (s.decls) |decl| {
            prefixFilterPass(decl.name, &.{prefix}) orelse {
                count += 1;
            };
        }
        break :blk count;
    };
}
fn countE(s: std.builtin.Type.Struct) u32 {
    return countDeclWithPrefix(s, "enum_");
}

fn cEnumNames(s: std.builtin.Type.Struct) [countE(s)][]const u8 {
    var names: [countE(s)][]const u8 = undefined;
    var idx: u32 = 0;
    for (s.decls) |decl| {
        if (isCEnumName(decl.name)) {
            names[idx] = decl.name;
            idx += 1;
        }
    }
    return names;
}

fn printDeclSummary(writer: anytype, comptime basic: type) void {
    const top_kind = Kind.of(basic);
    const as_struct = top_kind.lower_type.Struct;

    const tu = @typeInfo(std.builtin.Type).Union;
    const bin_num = tu.fields.len;
    var bins: [bin_num]u32 = .{0} ** bin_num;
    var counted: u32 = 0;

    const prefs: []const []const u8 = &.{ "__", "_", "offsetof", "WGPU_" };
    for (as_struct.decls) |decl| {
        prefixFilterPass(decl.name, prefs) orelse continue;
        const member = Kind.fieldOf(basic, decl.name) orelse continue;

        const bin_id: u32 = @intFromEnum(std.meta.activeTag(member.lower_type));
        bins[bin_id] += 1;
        counted += 1;
    }
    writer.print("+++ valid decls {d}/{d}\n", .{ counted, bin_num }) catch unreachable;
    for (tu.fields, 0..) |field, i| {
        const curr_bin = bins[i];
        if (curr_bin > 0)
            writer.print("{s} - {d}\n", .{ field.name, curr_bin }) catch unreachable;
    }
    const a = cEnumNames(as_struct);
    writer.print("c_enums {d}\n", .{a.len}) catch unreachable;
    for (a) |name| {
        writer.print("- {s}\n", .{name}) catch unreachable;
    }
}

fn writeSummary(writer: anytype, about: type) void {
    const name = @typeName(about);
    const as_struct = @typeInfo(about).Struct;
    const f_n = as_struct.fields.len;

    const fld_num: u32 = as_struct.fields.len;
    const decl_num: u32 = as_struct.decls.len;

    writer.print("+++ looking at:\n\t{s} (f {d}) (d {d})\n", .{ name, fld_num, decl_num }) catch unreachable;

    for (as_struct.fields) |field| {
        writer.print("\t{s},", .{field.name}) catch unreachable;
    }
    if (f_n != 0) writer.print("\n", .{}) catch unreachable;

    printDeclSummary(writer, about);
    // printDeclaration(writer, about);
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
    examineType(cModule);
    // examineType(zigModule);
    // examineType(generatedProtobuffer);
}
