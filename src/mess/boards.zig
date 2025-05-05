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

pub fn SquareBoard(x_dim: u8, z_dim: u8) type {
    const b_size = Size2D.init(x_dim, z_dim);
    return struct {
        const Self = @This();
        pub const Sz: Size2D = b_size;

        alloc: Allocator,

        x_v: []f32,
        y_v: []f32,
        z_v: []f32,
        level: f32 = -0.5,

        pub fn init(a: Allocator) !Self {
            const n = Self.Sz.len;
            var prefab = Self{
                .alloc = a,
                .x_v = try a.alloc(f32, n),
                .y_v = try a.alloc(f32, n),
                .z_v = try a.alloc(f32, n),
            };
            prefab.initPos();
            return prefab;
        }

        pub fn deinit(self: *Self) void {
            const slices = [3][]f32{ self.x_v, self.y_v, self.z_v };
            for (slices) |s| {
                self.alloc.free(s);
            }
        }

        fn initPos(self: *Self) void {
            const sz = Self.Sz;
            for (0..sz.len) |x_idx|
                self.x_v[x_idx] = @floatFromInt(@mod(x_idx, sz.x_dim));

            const dz = sz.z_dim;
            for (0..sz.z_dim) |z_idx| {
                const row_start = z_idx * dz;
                const row_value: f32 = @floatFromInt(z_idx);
                const row_memory = self.z_v[row_start .. row_start + dz];
                @memset(row_memory, row_value);
            }

            @memset(self.y_v, self.level);

            math.center(self.x_v);
            math.center(self.z_v);
        }

        pub fn debugInfo(self: *const Self) void {
            const x_mm = math.minMax(self.x_v);
            const y_mm = math.minMax(self.y_v);
            const z_mm = math.minMax(self.z_v);
            std.debug.print("+++ X {d} {d}\n", .{ x_mm[0], x_mm[1] });
            std.debug.print("+++ Y {d} {d}\n", .{ y_mm[0], y_mm[1] });
            std.debug.print("+++ Z {d} {d}\n", .{ z_mm[0], z_mm[1] });
        }
    };
}

// OH wait... We could extract Board from chess board
// Player could move on a borad, but not just on chess board
// it could be also other type of boards and player could move
// along its fields
pub fn Chessboard(x_dim: u32, z_dim: u32) type {
    const Grid = SquareBoard(x_dim, z_dim);
    return struct {
        const Self = @This();
        pub const Sz = Grid.Sz;
        alloc: Allocator,
        board: Grid,
        scale: rl.Vector3 = math.asRlvec3(.{ Sz.x_dim, 1, Sz.z_dim }),
        col: []rl.Color,
        mesh: ?rl.Mesh = null,
        material: ?rl.Material = null,

        pub fn init(a: Allocator) !Self {
            const n = Self.Sz.len;
            var prefab = Self{
                .alloc = a,
                .board = try Grid.init(a),
                .col = try a.alloc(rl.Color, n),
            };
            prefab.calcColor();
            return prefab;
        }

        pub fn deinit(self: *Self) void {
            self.alloc.free(self.col);
            self.board.deinit();
        }

        fn calcColor(self: *Self) void {
            const size = Self.Sz;
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

        pub fn repr(self: *Self) void {
            const b: *Grid = &self.board;
            for (b.x_v, b.y_v, b.z_v, self.col) |x, y, z, c| {
                var pos = rl.Vector3.init(x, y, z);
                pos = pos.multiply(self.scale);
                const cube_size = rl.Vector3.init(1, 0.33, 1);
                rl.drawCubeWiresV(pos, cube_size, c);

                // const transform = rl.Matrix.translate(pos.x, pos.y, pos.z);
                // rl.drawMesh(self.mesh.?, self.material.?, transform);
            }
        }
    };
}

const Osc = @import("osc.zig").Osc;

fn newLn8(i: usize) void {
    if (@mod(i, 8) == 7) {
        std.debug.print("\n", .{});
    }
}

pub fn WobblyChessboard(x_dim: u32, z_dim: u32) type {
    const BoardTpy = Chessboard(x_dim, z_dim);
    return struct {
        const Self = @This();
        alloc: Allocator,

        board: BoardTpy,
        sim: []Osc,
        wobblyAmp: f32,

        pub fn init(alloc: Allocator) !Self {
            var prefab = Self{
                .alloc = alloc,
                .board = try BoardTpy.init(alloc),
                .sim = try alloc.alloc(Osc, BoardTpy.Sz.len),
                .wobblyAmp = 0.33,
            };

            prefab.bootstrapSim();
            return prefab;
        }

        fn bootstrapSim(self: *Self) void {
            const brd = &self.board.board;
            for (0..BoardTpy.Sz.len) |i| {
                const x = brd.x_v[i];
                const y = brd.z_v[i];
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
            const len = BoardTpy.Sz.len;
            const brd = &self.board.board;
            var aplied: [len]f32 = undefined;
            for (0..len) |i| {
                self.sim[i].update(delta_ms);
                aplied[i] = self.sim[i].sample() - 0.5;
            }
            @memcpy(brd.y_v, aplied[0..len]);
        }

        pub fn oscInfo(self: *Self) void {
            const size = BoardTpy.Sz;
            const osc_v = self.sim;
            for (0..size.len) |i| {
                std.debug.print(" p {d: <4} ", .{osc_v[i].phase});
                newLn8(i);
            }
            std.debug.print("\n", .{});
            for (0..size.len) |i| {
                std.debug.print(" y {d: <4} ", .{osc_v[i].sample()});
                newLn8(i);
            }
        }
    };
}
const player = @import("player.zig");
const Move = player.Move;
const Player = player.Player;

pub fn WorldNavigBoard() type {
    const BoardBase = WobblyChessboard(8, 8);

    return struct {
        const Self = @This();
        const Forward: math.fvec3 = .{ 1, 0, 0 };
        const Backward: math.fvec3 = .{ -1, 0, 0 };
        const Left: math.fvec3 = .{ 0, 0, -1 };
        const Right: math.fvec3 = .{ 0, 0, 1 };

        board: BoardBase,
        alloc: Allocator,
        phase: f32 = 0,

        pub fn init(alloc: Allocator) !Self {
            return Self{
                .alloc = alloc,
                .board = try BoardBase.init(alloc),
            };
        }

        const Limit = struct {
            val: f32,
            lim: f32,
        };

        pub fn allowMove(self: *Self, next: rl.Vector3) bool {
            const quadra = math.quadra;
            //całe to porównywanie mogbło by się odbywać na innym "poziomie"
            _ = self;
            const glob_lim = 4.5;

            const to_limit = [_]Limit{
                Limit{ .val = next.x, .lim = comptime quadra(glob_lim) },
                Limit{ .val = next.z, .lim = comptime quadra(glob_lim) },
            };
            var allow_move: bool = true;
            for (to_limit) |rules| {
                allow_move = allow_move and math.quadra(rules.val) <= rules.lim;
            }
            return allow_move;
        }

        fn decodeMove(self: *Self, move: Move) rl.Vector3 {
            // TODO Doszedłem do takiego wniosku, że dobrze by było zmieniać kierunek wraz z obrotem kamery
            //      no bo jak teraz ta kamera tak sobie orbituje, to gdy kąt już zmieni się wystarczająco
            //      kierunki zaczynają się nieintuicyjnie dla użytkownika zmieniać
            //
            // Zawsze mogę nie ruszać kamerą xD
            // wraz z ewolucją świata, wektory ruchmu mogą ulegać zmianie, na podstawie potencjalnego
            // self.state
            //
            _ = self;
            return switch (move) {
                .up => math.asRlvec3(Self.Forward),
                .down => math.asRlvec3(Self.Backward),
                .left => math.asRlvec3(Self.Left),
                .right => math.asRlvec3(Self.Right),
                .no_move => rl.Vector3.zero(),
            };
        }

        pub fn traverse(self: *Self, pamperek: *Player, move: Move) rl.Vector3 {
            const delta = self.decodeMove(move);
            var travel_to = pamperek.pos;
            const dst = travel_to.add(delta);
            self.phase = pamperek.cam_phase;

            if (self.allowMove(dst)) {
                travel_to = dst;
            }
            return travel_to;
        }

        pub fn deinit(self: *Self) void {
            self.board.deinit();
        }

        pub fn repr(self: *Self) void {
            self.board.board.repr();

            const dirs: []const math.fvec3 = &.{
                Self.Forward,
                Self.Right,
                Self.Backward,
                Self.Left,
            };

            const origin = rl.Vector3.init(0, 1, 0);
            const mult: math.fvec3 = @splat(3);
            for (dirs) |dir| {
                const rlvec = math.asRlvec3(dir * mult);
                rl.drawLine3D(origin, origin.add(rlvec), rl.Color.maroon);
            }

            var osc_calc = Osc{ .phase = self.phase };
            const xz = osc_calc.sample2D();
            const rlxz = rl.Vector3.init(xz[0], 0, xz[1]).scale(-1);
            const xz_origin = origin.add(origin.scale(0.5));
            rl.drawLine3D(xz_origin, xz_origin.add(rlxz), rl.Color.white);

            var max_id: u8 = 0;
            var max_similarity: f32 = -1;
            const xz_fvec = math.asFvec3(rlxz);
            for (dirs, 0..) |dir, i| {
                const val = math.dot(dir, xz_fvec);
                if (val > max_similarity) {
                    max_id = @intCast(i);
                    max_similarity = val;
                }
            }
            const sim_origin = origin.add(origin);
            const aligned = math.asRlvec3(dirs[max_id]);
            rl.drawLine3D(sim_origin, sim_origin.add(aligned), rl.Color.black);
        }
    };
}
