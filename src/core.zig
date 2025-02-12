const std = @import("std");
const Allocator = std.mem.Allocator;

pub const AppMamory = struct {
    gpa: Allocator,
    arena: Allocator,
};

const InternalMain = *const fn (memory: *const AppMamory) void;

pub fn DeployInMemory(program: InternalMain) void {
    var fmt_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_arena = std.heap.ArenaAllocator.init(obj_gpa.allocator());
    defer {
        _ = obj_arena.deinit();
        _ = obj_gpa.deinit();
        _ = fmt_gpa.deinit();
    }

    const mm = AppMamory{
        .gpa = fmt_gpa.allocator(),
        .arena = obj_arena.allocator(),
    };

    program(&mm);
}
