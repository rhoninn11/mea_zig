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

    pub inline fn idx(self: Size2D, x: u32, z: u32) u32 {
        return x + z * self.x_dim;
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
        surface_level: f32 = -0.5,
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

            const y_pos = self.z_pos;
            for (0..size.z_dim) |z| {
                const row_idx = z * size.z_dim;
                const row_value: f32 = @floatFromInt(z);
                const row_memory = y_pos[row_idx .. row_idx + size.x_dim];
                @memset(row_memory, row_value);
            }
            @memset(self.y_pos, self.surface_level);

            math.center(self.x_pos);
            math.center(self.z_pos);
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
            for (self.x_pos, self.y_pos, self.z_pos, self.col) |x, y, z, c| {
                var pos = rl.Vector3.init(x, y, z);
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

const Osc = @import("osc.zig").Osc;

pub fn WobblyChessboard() type {
    const BordType = Chessboard(8, 8);

    return struct {
        const Self = @This();
        alloc: Allocator,

        board: BordType,
        sim: []Osc,

        pub fn init(alloc: Allocator) !Self {
            var prefab = Self{
                .alloc = alloc,
                .board = try BordType.init(alloc),
                .sim = try alloc.alloc(Osc, BordType.chess_size.len),
            };

            prefab.bootstrapSim();
            return prefab;
        }

        fn bootstrapSim(self: *Self) void {
            for (0..BordType.chess_size.len) |i| {
                self.sim[i].phase = self.board.x_pos[i];
                self.sim[i].freq = self.board.z_pos[i];
                self.sim[i].amp = 1;
            }
        }

        pub fn deinit(self: *Self) void {
            self.alloc.free(self.sim);
            self.board.deinit();
        }

        pub fn update(self: *Self, delta_ms: f32) void {
            const len = BordType.chess_size.len;
            var aplied: [len]f32 = undefined;
            for (0..len) |i| {
                self.sim[i].update(delta_ms);
                aplied[i] = self.sim[i].sample();
            }
            @memcpy(self.board.y_pos, aplied[0..len]);
        }

        pub fn oscInfo(self: *Self) void {
            const size = BordType.chess_size;
            const ids: []const u32 = &.{ 0, size.x_dim };
            var oscs = [_]Osc{ self.sim[0], self.sim[size.x_dim] };
            for (0..oscs.len) |i| {
                const sample = oscs[i].sample();
                oscs[i].log();
                std.debug.print("osc: {d}, sampled: {d}\n", .{ ids[i], sample });
            }
        }
    };
}
