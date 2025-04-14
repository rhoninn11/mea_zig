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

// OH wait... We could extract Board from chess board
// Player could move on a borad, but not just on chess board
// it could be also other type of boards and player could move
// along its fields
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
            const brd_size = Self.chess_size;
            for (self.x_pos, self.y_pos, self.z_pos, self.col) |x, y, z, c| {
                var pos = rl.Vector3.init(x, y, z);
                pos = pos.multiply(rl.Vector3.init(brd_size.x_dim, 1, brd_size.z_dim));
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

fn newLn8(i: usize) void {
    if (@mod(i, 8) == 7) {
        std.debug.print("\n", .{});
    }
}

pub fn WobblyChessboard() type {
    const BordType = Chessboard(8, 8);

    return struct {
        const Self = @This();
        alloc: Allocator,

        board: BordType,
        sim: []Osc,
        wobblyAmp: f32,

        pub fn init(alloc: Allocator) !Self {
            var prefab = Self{
                .alloc = alloc,
                .board = try BordType.init(alloc),
                .sim = try alloc.alloc(Osc, BordType.chess_size.len),
                .wobblyAmp = 0.33,
            };

            prefab.bootstrapSim();
            return prefab;
        }

        fn bootstrapSim(self: *Self) void {
            for (0..BordType.chess_size.len) |i| {
                const x = self.board.x_pos[i];
                const y = self.board.z_pos[i];
                var total = rl.Vector2.init(x * 2, y * 2).length();
                if (total >= 1.0) {
                    total = 1;
                }

                self.sim[i].phase = total * 3.14 + 3.14 / 2.0;
                self.sim[i].freq = 1;
                self.sim[i].amp = self.wobblyAmp * (total);
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
                aplied[i] = self.sim[i].sample() - 0.5;
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
            for (0..self.sim.len) |i| {
                std.debug.print(" p {d: <4} ", .{self.sim[i].phase});
                newLn8(i);
            }
            std.debug.print("\n", .{});

            for (0..self.board.y_pos.len) |i| {
                const val = self.board.y_pos[i];
                std.debug.print(" y {d: <4} ", .{val});
                newLn8(i);
            }
        }
    };
}

pub fn NavigationBoard() type {
    const BoardBase = Chessboard(16, 16);

    return struct {
        const Self = @This();
        board: BoardBase,
        alloc: Allocator,

        pub fn init(alloc: Allocator) !Self {
            return Self{
                .alloc = alloc,
                .board = try BoardBase.init(alloc),
            };
        }

        pub fn deinit(self: *Self) void {
            self.board.deinit();
        }

        pub fn repr(self: *Self) void {
            self.board.repr();
        }
    };
}
