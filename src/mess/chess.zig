const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");
const Allocator = std.mem.Allocator;

pub fn ChessRenderState(_x: u32, _y: u32) type {
    return struct {
        const Self = @This();
        const xn = _x;
        const yn = _y;
        pub const fields = _x * _y;
        alloc: Allocator,
        x_pos: []f32,
        y_pos: []f32,
        z_pos: []f32,
        col: []rl.Color,

        pub fn deinit(self: Self) void {
            const alloc = self.alloc;
            alloc.free(self.x_pos);
            alloc.free(self.y_pos);
            alloc.free(self.z_pos);
            alloc.free(self.col);
        }

        fn initPos(self: *Self, sz: anytype) void {
            const x_pos = self.x_pos;
            @memset(x_pos, 3);
            for (0..sz.fields) |x| x_pos[x] = @floatFromInt(@mod(x, 8));

            const y_pos = self.y_pos;
            for (0..sz.yn) |y| {
                const row_idx = y * sz.yn;
                const row_value: f32 = @floatFromInt(y);
                const row_memory = y_pos[row_idx .. row_idx + sz.xn];
                @memset(row_memory, row_value);
            }
            @memset(self.z_pos, 0);

            math.center(self.x_pos);
            math.center(self.y_pos);
        }

        pub fn init(alloc: Allocator) !Self {
            const n = Self.fields;
            var state = Self{
                .alloc = alloc,
                .x_pos = try alloc.alloc(f32, n),
                .y_pos = try alloc.alloc(f32, n),
                .z_pos = try alloc.alloc(f32, n),
                .col = try alloc.alloc(rl.Color, n),
            };

            state.initPos(.{
                .fields = Self.fields,
                .xn = Self.xn,
                .yn = Self.yn,
            });

            for (0..Self.fields) |i| {
                const row_flip = @mod(@divTrunc(i, 8), 2);
                state.col[i] = switch (@mod(i + row_flip, 2)) {
                    inline 0 => rl.Color.white,
                    inline 1 => rl.Color.black,
                    else => unreachable,
                };
            }
            return state;
        }

        pub fn repr(self: Self) void {
            const shared_y = -0.5;
            for (self.x_pos, self.y_pos, self.z_pos, self.col) |x, z, y, c| {
                _ = y;
                var pos = rl.Vector3.init(x, shared_y, z);
                pos = pos.multiply(rl.Vector3.init(8, 1, 8));
                const size = rl.Vector3.init(1, 0.33, 1);
                rl.drawCubeWiresV(pos, size, c);
            }
        }

        pub fn debugInfo(self: *Self) void {
            const x_mm = math.minMax(self.x_pos);
            const y_mm = math.minMax(self.y_pos);
            const z_mm = math.minMax(self.z_pos);
            std.debug.print("+++ X {d} {d}\n", .{ x_mm[0], x_mm[1] });
            std.debug.print("+++ Y {d} {d}\n", .{ y_mm[0], y_mm[1] });
            std.debug.print("+++ Z {d} {d}\n", .{ z_mm[0], z_mm[1] });
        }
    };
}
