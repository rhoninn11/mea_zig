const std = @import("std");

// js side
extern fn consoleLog(ptr: [*]const u8, len: usize) void;

export fn callFromVm() void {
    const consoleMsg: []const u8 = "+++ zigmunt is writing letter to Santa Clouse";

    consoleLog(consoleMsg.ptr, consoleMsg.len);
}

export fn vmLog(ptr: [*]const u8, len: usize) void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer _ = arena.deinit();

    const progress_info = "+++ ok so now we will try to alloc new string";
    consoleLog(progress_info.ptr, progress_info.len);

    const consoleMsg: []const u8 = "+++ what i should do about that, zigmunt said ->";
    const halo = std.fmt.allocPrint(allocator, "{s} {s}", .{ consoleMsg, ptr[0..len] }) catch {
        const error_info: []const u8 = "!!! alloc error\n";
        consoleLog(error_info.ptr, error_info.len);
        return;
    };

    consoleLog(halo.ptr, halo.len);
}
