const std = @import("std");
const rl = @import("raylib");

pub fn bypassAssert(cond: bool, comptime bypas: bool) void {
    if (!bypas) {
        std.debug.assert(cond);
    }
}

pub fn rlDebugMaterialLocations(mat: *rl.Material) void {
    const s_size = @sizeOf(rl.Shader);
    const m_size = @sizeOf(rl.Material);
    const locs = @typeInfo(rl.ShaderLocationIndex).Enum;
    const shader = mat.shader;
    const shader_locs = shader.locs;
    var val: c_int = 0;

    std.debug.print("-----------------------------------------\n", .{});
    defer std.debug.print("-----------------------------------------\n", .{});

    std.debug.print(
        "-- Material struct size {d}\n,--- Shader struct size {d}\n",
        .{ m_size, s_size },
    );
    std.debug.print("-- Shader id {d}\n", .{shader.id});

    inline for (locs.fields) |loc| {
        val = shader_locs[loc.value];
        if (val != -1) {
            std.debug.print("-- {d} {s} {d}\n", .{ loc.value, loc.name, shader_locs[loc.value] });
        }
    }
}
