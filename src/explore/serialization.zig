const std = @import("std");
const json = std.json;
const ParseOptions = json.ParseOptions;
const Allocator = std.mem.Allocator;
const OpenFlags = std.fs.File.OpenFlags;

const Prompt = struct {
    prompt: []u8 = "",
};

const KB = 1024;

pub fn openPrompt(alloc: Allocator, file_path: []u8) !void {
    // otworzyć plik
    const file = try std.fs.cwd().openFile(file_path, OpenFlags{});
    const reader = file.reader();
    const buffer = try reader.readAllAlloc(alloc, KB * 2);
    defer alloc.free(buffer);

    const cache = try json.parseFromSlice(Prompt, alloc, buffer, ParseOptions{});
    defer cache.deinit();

    const external_prompt = cache.value;
    std.debug.print("+++ Prompt from file was: {s}\n", .{external_prompt.prompt});
}
