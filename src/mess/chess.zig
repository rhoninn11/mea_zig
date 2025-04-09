const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");
const Allocator = std.mem.Allocator;

const Size2D = struct {
    len: u32,
    x_dim: u32,
    z_dim: u32,

    pub fn init(x: u32, z: u32) Size2D {
        return Size2D{
            .x_dim = x,
            .z_dim = z,
            .len = x * z,
        };
    }
};

pub fn Chessboard(_x: u32, _y: u32) type {
    return struct {
        const Self = @This();
        pub const chess_size = Size2D.init(_x, _y);
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

        fn calcPos(self: *Self, size: Size2D) void {
            const x_pos = self.x_pos;
            @memset(x_pos, 3);
            for (0..size.len) |x|
                x_pos[x] = @floatFromInt(@mod(x, 8));

            const y_pos = self.y_pos;
            for (0..size.z_dim) |z| {
                const row_idx = z * size.z_dim;
                const row_value: f32 = @floatFromInt(z);
                const row_memory = y_pos[row_idx .. row_idx + size.x_dim];
                @memset(row_memory, row_value);
            }
            @memset(self.z_pos, 0);

            math.center(self.x_pos);
            math.center(self.y_pos);
        }

        fn calcColor(self: *Self, size: Size2D) void {
            for (0..size.len) |i| {
                const odd_row = @divTrunc(i, size.x_dim);
                const row_flip = @mod(odd_row, 2);
                self.col[i] = switch (@mod(i + row_flip, 2)) {
                    inline 0 => rl.Color.white,
                    inline 1 => rl.Color.black,
                    else => unreachable,
                };
            }
        }

        pub fn init(alloc: Allocator) !Self {
            const n = Self.chess_size.len;
            var state = Self{
                .alloc = alloc,
                .x_pos = try alloc.alloc(f32, n),
                .y_pos = try alloc.alloc(f32, n),
                .z_pos = try alloc.alloc(f32, n),
                .col = try alloc.alloc(rl.Color, n),
            };

            state.calcPos(Self.chess_size);
            state.calcColor(Self.chess_size);

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

        pub fn debugInfo(self: *const Self) void {
            const x_mm = math.minMax(self.x_pos);
            const y_mm = math.minMax(self.y_pos);
            const z_mm = math.minMax(self.z_pos);
            std.debug.print("+++ X {d} {d}\n", .{ x_mm[0], x_mm[1] });
            std.debug.print("+++ Y {d} {d}\n", .{ y_mm[0], y_mm[1] });
            std.debug.print("+++ Z {d} {d}\n", .{ z_mm[0], z_mm[1] });
        }
    };
}
