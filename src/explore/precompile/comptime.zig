const std = @import("std");
const meta = std.meta;
const cModule = @cImport({
    @cInclude("webgpu.h");
});

const zigModule = @import("testnaemspace.zig");
const generatedProtobuffer = @import("../../gen/comfy.pb.zig");

// -----
pub fn examineWegGPU() void {
    const webGPUHeader = @cImport({
        @cInclude("webgpu.h");
    });
    const comptime_module_summary = comptime typeSummary(webGPUHeader);
    // show at runtime
    std.debug.print("{s}\n", .{comptime_module_summary});

    //
    //  Ale domyślny cel jest taki, żeby znaleźć wszystkie enumy i stworzyć dla nich funkcję,
    //  która będzie zwracała nazwy wszystkich pól jako stringi, tak żeby w runtimeie można było
    //  potem je odczytać

}
fn summaryLen(about: type) u64 {
    var counter = std.io.countingWriter(std.io.null_writer);
    writeSummary(counter.writer().any(), about);
    return counter.bytes_written;
}

fn printEnum(summ: Raport, e: Kind) void {
    const enumInfo = e.lower_type.Enum;
    const filed_len = enumInfo.fields.len;
    // const d_n = enumInfo.decls.len;
    summ.addInfo(" (f {d})\n", .{filed_len});

    for (enumInfo.fields) |field| {
        summ.addInfo(
            " - {d} - {s: <10}",
            .{ field.value, field.name },
        );
    }
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

fn hasPrefix(name: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, name, prefix);
}

fn hasPrefixV(name: []const u8, comptime prefixV: []const []const u8) bool {
    for (prefixV) |pref| {
        if (hasPrefix(name, pref)) return true;
    }
    return false;
}

fn printType(to: Raport) void {
    const u = @typeInfo(std.builtin.Type).Union;
    to.addInfo("f{d} d{d}\n", .{ u.fields.len, u.decls.len });
}

// print declaration of struct to writer
fn printDeclaration(to: Raport, comptime basic: type) void {
    const top_kind = Kind.of(basic);
    const as_struct = top_kind.lower_type.Struct;

    const prefs: []const []const u8 = &.{ "__", "_", "offsetof", "WGPU_" };
    for (as_struct.decls) |decl| {
        if (hasPrefixV(decl.name, prefs)) continue;
        const valid_member = Kind.fieldOf(basic, decl.name) orelse continue;

        to.addInfo(
            "\n{s: <16} | {s: >7} | {s}",
            .{ decl.name, valid_member.lower_name, valid_member.base_name },
        );
        switch (valid_member.lower_type) {
            // .Enum => printEnum(writer, member),
            .Union => to.newLn("+++"),
            else => {},
        }
    }
}

const Struct = std.builtin.Type.Struct;
const Declaration = std.builtin.Type.Declaration;
const c_enum_prefix = "enum_";

fn countPrefix(decls: []const Declaration, prefix: []const u8) u32 {
    return comptime blk: {
        var count: u32 = 0;
        for (decls) |d| {
            if (hasPrefix(d.name, prefix)) {
                count += 1;
            }
        }
        break :blk count;
    };
}

fn cEnumNames(decls: []const Declaration, comptime len: u32) [len][]const u8 {
    var names: [len][]const u8 = undefined;
    var idx: u32 = 0;
    for (decls) |decl| {
        if (hasPrefix(decl.name, c_enum_prefix)) {
            names[idx] = decl.name;
            idx += 1;
        }
    }
    return names;
}

fn printDeclSummary(summ: *Raport, comptime basic: type) void {
    const top_kind = Kind.of(basic);
    const as_struct = top_kind.lower_type.Struct;
    const declarations = as_struct.decls;

    const tu = @typeInfo(std.builtin.Type).Union;
    const bin_num = tu.fields.len;
    var bins: [bin_num]u32 = .{0} ** bin_num;
    var counted: u32 = 0;

    // counting valid declarations, to simplicity decls buffer large enought
    const garbage_prefs: []const []const u8 = &.{ "__", "_", "offsetof", "WGPU_" };
    var decls_scrachpad: [4096]Declaration = undefined;
    for (declarations) |decl| {
        if (hasPrefixV(decl.name, garbage_prefs)) continue;
        const member = Kind.fieldOf(basic, decl.name) orelse continue;

        const bin_id: u32 = @intFromEnum(std.meta.activeTag(member.lower_type));
        decls_scrachpad[counted] = decl;
        bins[bin_id] += 1;
        counted += 1;
    }

    const valid_decl: []Declaration = decls_scrachpad[0..counted];

    // var filterd_decls: [counted]Declaration = undefined;
    // var idx: u32 = 0;
    // for (declarations) |decl| {
    //     const processed = Kind.fieldOf(basic, decl.name);
    //     if (!hasPrefixV(decl.name, prefs) and processed != null) {
    //         filterd_decls[idx] = decl;
    //         idx += 1;
    //     }
    // }

    summ.addInfo(
        "+++ valid decls {d}/{d}\n",
        .{ counted, bin_num },
    );
    for (tu.fields, 0..) |field, i| {
        const curr_bin = bins[i];
        if (curr_bin > 0) {
            summ.addInfo(
                "{s} - {d}\n",
                .{ field.name, curr_bin },
            );
        }
    }

    cEnumsInfo(summ, valid_decl);
}
fn cEnumsInfo(info: *Raport, decls: []const Declaration) void {
    const e_prefix = "enum_";
    const e_count = countPrefix(decls, e_prefix);
    const e_names = cEnumNames(decls, e_count);
    info.addInfo("---- cenums ({d}) -----\n", .{e_count});
    var enum_field_num = 0;
    defer info.addInfo("---- total: {d}\n", .{enum_field_num});

    var names: [128][]const u8 = undefined;
    for (e_names) |name| {
        const enum_name = name[e_prefix.len..name.len];
        var count = 0;
        for (decls) |d| {
            const decl_name = d.name;
            if (hasPrefix(decl_name, enum_name)) {
                names[count] = decl_name;
                count += 1;
            }
        }
        enum_field_num += count;
        info.addInfo(
            "- {s} - {d}: ",
            .{ enum_name, count },
        );
        for (names[0..count]) |print_name| {
            info.addInfo("{s}, ", .{print_name});
        }
        info.newLn("");
    }
}

const Raport = struct {
    wrt: std.io.AnyWriter,
    pub inline fn addInfo(self: *Raport, comptime format: []const u8, args: anytype) void {
        self.wrt.print(format, args) catch unreachable;
    }
    pub inline fn newLn(self: *Raport, prefix: []const u8) void {
        self.wrt.print("{s}\n", .{prefix}) catch unreachable;
    }
};

fn writeSummary(writer: std.io.AnyWriter, about: type) void {
    const name = @typeName(about);
    const as_struct = @typeInfo(about).Struct;
    const f_n = as_struct.fields.len;

    const fld_num: u32 = as_struct.fields.len;
    const decl_num: u32 = as_struct.decls.len;

    var summ = Raport{ .wrt = writer };
    summ.addInfo("+++ looking at:\n\t{s} (f {d}) (d {d})\n", .{ name, fld_num, decl_num });

    for (as_struct.fields) |field| {
        summ.addInfo("\t{s},", .{field.name});
    }
    if (f_n != 0) summ.newLn();

    printDeclSummary(&summ, about);
    // printDeclaration(writer, about);
    summ.newLn("");
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

pub fn comptimeExperiment() void {
    examineWegGPU();
    // examineType();
    // examineType(zigModule);
    // examineType(generatedProtobuffer);
}

const fs = std.fs;
const _test = std.testing;
test "can i use file structure in comptime?" {
    const cwd = fs.cwd();
    cwd.access("build.zig", .{ .mode = .read_only }) catch {
        try _test.expect(false);
    };

    cwd.access("main.zig", .{ .mode = .read_only }) catch {
        try _test.expect(true);
    };

    // here we want to test is file structure data is accesible at comptime
}
