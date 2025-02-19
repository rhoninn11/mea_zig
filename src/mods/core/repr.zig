const std = @import("std");
const rl = @import("raylib");

const math = @import("math.zig");

const fv2 = math.vf2;
const f2i = math.f2i;

pub const Theme = [_]rl.Color{ rl.Color.black, rl.Color.beige };

pub fn frame(spot: fv2, active: bool) void {
    const defCol = if (active) rl.Color.yellow else rl.Color.dark_green;
    const rl_spot = @Vector(2, i32){ f2i(spot[0]), f2i(spot[1]) };
    rl.drawRectangle(rl_spot[0] - 25, rl_spot[1] - 25, 50, 50, defCol);
}

pub fn blob(spot: fv2, active: bool, size: f32) void {
    const defCol = if (active) rl.Color.maroon else rl.Color.white;
    const rl_spot = @Vector(2, i32){ f2i(spot[0]), f2i(spot[1]) };
    rl.drawCircle(rl_spot[0], rl_spot[1], size, defCol);
}

pub fn cBlob(spot: fv2, color: rl.Color, size: f32) void {
    const defCol = color;
    const rl_spot = @Vector(2, i32){ f2i(spot[0]), f2i(spot[1]) };
    rl.drawCircle(rl_spot[0], rl_spot[1], size, defCol);
}

pub const Tile = struct {
    pos: fv2,
    size: f32,
    color: rl.Color,
};

pub fn tBlob(t: Tile) void {
    const rl_spot = @Vector(2, i32){ f2i(t.pos[0]), f2i(t.pos[1]) };
    rl.drawCircle(rl_spot[0], rl_spot[1], t.size, t.color);
}

pub const Tyler = struct {
    const Kind: type = Tile;
    const reprFn: type = (*const fn (of: *Kind) void);

    __repr__: reprFn = tBlob,
    kind: Kind,
};
