const std = @import("std");

// i would like to to test here some properties of cli
// eg simple animation... in go i was stumbled once on info about
// cli commands like "clear line" or similar, could i replicate it
// also in zig?

pub fn smallPause(ms: u64) void {
    const to_ms = std.time.ns_per_ms;
    std.time.sleep(ms * to_ms);
}

pub fn program() void {
    cliDemo() catch {
        std.debug.print("error bulbe out", .{});
    };
}

const KB = 1024;
var f_buff: [8 * KB]u8 = undefined;

pub fn cliDemo() !void {
    var fba = std.heap.FixedBufferAllocator.init(&f_buff);
    var a = fba.allocator();
    a = a;

    const stdout = std.io.getStdOut();
    defer stdout.close();
    const ms_glob = 60;
    // i can write to it like ordinary file to see output on terminal?
    const allText: []const []const u8 = &.{
        "i dont belive it will go\n",
        "and another one\n",
        "\\033[1A\\033[K\n",
        "this method do not work on stdout file\n",
        "\n", // ok endline is also one character... idono, lastly utf8 experience made me questioning some things:D
    };
    // by the way its partialy solution for creating .pc at build time
    for (allText) |batch| {
        var text: []const u8 = try std.fmt.allocPrint(a, "{s} {d}\n", .{ batch, batch.len });
        text = batch;
        try stdout.writeAll(text);
        smallPause(ms_glob);
    }
}
