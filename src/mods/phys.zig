const std = @import("std");
const vf2 = @import("../mess/math.zig").fv2;

fn asV(v: anytype) vf2 {
    return @splat(v);
}

pub const PhysInprint = struct {
    const Self = PhysInprint;

    f: vf2 = @splat(2),
    z: vf2 = @splat(1),
    r: vf2 = @splat(0),

    k1: vf2 = @splat(0),
    k2: vf2 = @splat(0),
    k3: vf2 = @splat(0),

    pub fn reecalc(self: *Self) void {
        const vpi: vf2 = comptime asV(std.math.pi);
        const vone: vf2 = comptime asV(1);
        const vtwo: vf2 = comptime asV(2);
        const vfour: vf2 = comptime asV(4);

        const intermed = vpi * self.f;
        self.k1 = self.z / (intermed);
        self.k2 = vone / (vfour * intermed * intermed);
        self.k3 = (self.r * self.k1) / vtwo;
    }

    pub fn new(f: f32, z: f32, r: f32) Self {
        var inst = Self{
            .f = @splat(f),
            .z = @splat(z),
            .r = @splat(r),
        };
        inst.reecalc();
        return inst;
    }
};

pub const Inertia = struct {
    const Self = Inertia;
    x: vf2,
    y: vf2,
    yd: vf2 = @splat(0),
    phx: ?*PhysInprint = null,

    pub fn simulate(self: *Self, td_ms: f32) void {
        std.debug.assert(td_ms < 100); //could crash app
        const tdv: vf2 = @splat(td_ms / 1000); //example time delta
        const xd: vf2 = @splat(0);
        if (self.phx) |phx| {
            const ydd = (self.x + phx.k3 * xd - self.y - phx.k1 * self.yd) / phx.k2;
            self.y = self.y + tdv * self.yd;
            self.yd = self.yd + tdv * ydd;
        }
    }

    pub fn spawn(spot: vf2) Self {
        return Inertia{
            .x = spot,
            .y = spot,
        };
    }

    pub fn setTarget(self: *Self, new_target: vf2) void {
        self.x = new_target;
    }

    pub fn getPos(self: *Self) vf2 {
        return self.y;
    }
};
