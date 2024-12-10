extern fn consoleOutput() void;

const std = @import("std");

export fn callFromVm() void {
    //    std.debug.print("+++ ciekawe co się z tym stanie", .{});
    consoleOutput();
}
