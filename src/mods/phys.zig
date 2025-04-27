const std = @import("std");
const Fvec2 = @import("../mess/math.zig").fv2;

pub fn InertiaPack(VecTpy: type) type {
    return struct {
        const vpi: VecTpy = asVec(std.math.pi);
        const vone: VecTpy = asVec(1);
        const vtwo: VecTpy = asVec(2);
        const vfour: VecTpy = asVec(4);

        pub inline fn asVec(val: anytype) VecTpy {
            return @splat(val);
        }

        pub const InertiaCfg: type = struct {
            const Self = @This();

            f: VecTpy = asVec(2),
            z: VecTpy = asVec(1),
            r: VecTpy = asVec(0),

            k1: VecTpy = asVec(0),
            k2: VecTpy = asVec(0),
            k3: VecTpy = asVec(0),

            // transform parameters from config config space to equation space
            pub inline fn reecalc(self: *Self) void {
                const intermed = vpi * self.f;
                self.k1 = self.z / (intermed);
                self.k2 = vone / (vfour * intermed * intermed);
                self.k3 = (self.r * self.k1) / vtwo;
            }

            pub fn new(f: f32, z: f32, r: f32) Self {
                var inst = Self{
                    .f = asVec(f),
                    .z = asVec(z),
                    .r = asVec(r),
                };
                inst.reecalc();
                return inst;
            }

            pub fn default() Self {
                var inst = Self{};
                inst.reecalc();
                return inst;
            }
        };

        pub const Inertia: type = struct {
            const Self = @This();
            x: VecTpy,
            y: VecTpy,
            yd: VecTpy = asVec(0),
            phx: ?InertiaCfg = null,

            pub inline fn simulate(self: *Self, td_ms: f32) void {
                //could calculate few samller steps as one big
                std.debug.assert(td_ms < 100); //crash app if optimalization is needed

                const tdv: VecTpy = asVec(td_ms / 1000); //example time delta
                const xd: VecTpy = asVec(0);
                if (self.phx) |phx| {
                    const ydd = (self.x + phx.k3 * xd - self.y - phx.k1 * self.yd) / phx.k2;
                    self.y = self.y + tdv * self.yd;
                    self.yd = self.yd + tdv * ydd;
                }
            }

            pub fn init(spot: VecTpy) Self {
                return Self{
                    .x = spot,
                    .y = spot,
                };
            }

            pub fn setTarget(self: *Self, new_target: VecTpy) void {
                self.x = new_target;
            }

            pub fn getPos(self: *Self) VecTpy {
                return self.y;
            }
        };
    };
}
inline fn asV(v: anytype) Fvec2 {
    return @splat(v);
}

const a = InertiaPack(Fvec2);
pub const PhysInprint = a.InertiaCfg;
pub const Inertia = a.Inertia;
