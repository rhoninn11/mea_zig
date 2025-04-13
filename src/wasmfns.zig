const std = @import("std");
const wasm_alloc = std.heap.wasm_allocator;
const page_alloc = std.heap.page_allocator;

// js side
extern fn consoleLog(ptr: [*]const u8, len: usize) void;
extern fn initRecording() void;

// ---------

export fn callFromVm() void {
    const consoleMsg: []const u8 = "+++ zigmunt is writing letter to Santa Clouse";

    consoleLog(consoleMsg.ptr, consoleMsg.len);
}

// TODO: czy jeste mi tu potrzebna współpraca z
// TODO: std.os.emscripten?
// TODO: std.wasm?

export fn vmLog(ptr: [*]const u8, len: usize) void {
    var arena = std.heap.ArenaAllocator.init(wasm_alloc);
    const arena_a = arena.allocator();
    defer _ = arena.deinit();
    _ = arena_a;
    _ = ptr;
    _ = len;

    const progress_info = "+++ before alloc";
    consoleLog(progress_info.ptr, progress_info.len);

    // TODO: nead to crack proper allocation in wasm context
    const consoleMsg: []const u8 = "+++ what i should do about that, zigmunt said ->";
    const halo = std.fmt.allocPrint(arena_a, "{s} {s}", .{ consoleMsg, ptr[0..len] }) catch {
        const error_info: []const u8 = "!!! alloc error\n";
        consoleLog(error_info.ptr, error_info.len);
        return;
    };
    consoleLog(halo.ptr, halo.len);

    const recording_info = "+++ now audio experiments";
    consoleLog(recording_info.ptr, recording_info.len);
    initRecording();
}

export fn onAudioFrame() void {}
