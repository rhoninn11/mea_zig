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

pub fn Grid2D(x_dim: u8, z_dim: u8) type {
    const b_size = Size2D.init(x_dim, z_dim);

    return struct {
        const Self = @This();
        pub const Sz: Size2D = b_size;

        fields: [Sz.len]math.fvec3 = undefined,

        pub fn init() Self {
            var prefab = Self{};
            const sz = Self.Sz;
            for (0..sz.len) |idx| {
                var pos: math.fvec3 = undefined;
                const x_idx = @mod(idx, sz.x_dim);
                const z_idx = @divFloor(idx, sz.z_dim);
                pos[0] = @floatFromInt(x_idx);
                pos[2] = @floatFromInt(z_idx);
                pos[1] = 0;
                prefab.fields[idx] = pos;
            }

            // math.center(self.x_v);
            // math.center(self.z_v);
            return prefab;
        }

        pub fn debugInfo(self: *const Self) void {
            var x_v: [Sz.len]f32 = undefined;
            var y_v: [Sz.len]f32 = undefined;
            var z_v: [Sz.len]f32 = undefined;
            for (0..Sz.len) |i| {
                const val = self.fields[i];
                x_v[i] = val[0];
                y_v[i] = val[1];
                z_v[i] = val[2];
            }
            const x_mm = math.minMax(&x_v);
            const y_mm = math.minMax(&y_v);
            const z_mm = math.minMax(&z_v);
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
    const Grid = Grid2D(x_dim, z_dim);
    return struct {
        const Self = @This();
        pub const Sz = Grid.Sz;
        board: Grid,
        scale: math.fvec3 = .{ Sz.x_dim, 1, Sz.z_dim },
        translation: math.fvec3 = .{ -32, -0.5, -32 },
        col: [Sz.len]rl.Color,

        mesh: ?rl.Mesh = null,
        material: ?rl.Material = null,

        pub fn init() Self {
            var prefab = Self{
                .board = Grid.init(),
                .col = undefined,
            };
            for (0..Sz.len) |i| {
                prefab.board.fields[i] *= prefab.scale;
                prefab.board.fields[i] += prefab.translation;
            }
            prefab.calcColor();
            return prefab;
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
            const cube_size = rl.Vector3.init(1, 0.33, 1);
            for (b.fields, self.col) |xyz, c| {
                const pos = xyz;
                rl.drawCubeWiresV(math.asRlvec3(pos), cube_size, c);

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
        pub const Sz = BoardTpy.Sz;
        alloc: Allocator,

        board: BoardTpy,
        sim: []Osc,
        wobblyAmp: f32,

        pub fn init(alloc: Allocator) !Self {
            var prefab = Self{
                .alloc = alloc,
                .board = BoardTpy.init(),
                .sim = try alloc.alloc(Osc, BoardTpy.Sz.len),
                .wobblyAmp = 0.33,
            };

            prefab.bootstrapSim();
            return prefab;
        }

        fn bootstrapSim(self: *Self) void {
            const brd = &self.board.board;
            for (0..BoardTpy.Sz.len) |i| {
                const pos = brd.fields[i];
                var total = rl.Vector2.init(pos[0] * 2, pos[2] * 2).length();
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
        }

        pub fn update(self: *Self, delta_ms: f32) void {
            const len = BoardTpy.Sz.len;
            const brd = &self.board.board;
            var aplied: [len]f32 = undefined;
            for (0..len) |i| {
                self.sim[i].update(delta_ms);
                aplied[i] = self.sim[i].sample() - 0.5;
                brd.fields[i][1] = aplied[i];
            }
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
        idx_x: u8 = 0,
        idx_z: u8 = 0,
        debug_pos: math.fvec3 = .{ 0, 1, 0 },

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

            const working_size = BoardBase.Sz;
            const allow = switch (move) {
                .up => self.idx_x < working_size.x_dim - 1,
                .down => self.idx_x > 0,
                .left => self.idx_z > 0,
                .right => self.idx_z < working_size.z_dim - 1,
                .no_move => false,
            };

            const grid_data = &self.board.board.board;
            if (allow) {
                const axis = switch (move) {
                    .up, .down => &self.idx_x,
                    .left, .right => &self.idx_z,
                    else => undefined,
                };

                std.debug.print("{d} {s}\n", .{ axis.*, @tagName(move) });
                switch (move) {
                    .up, .right => axis.* += 1,
                    .left, .down => axis.* -= 1,
                    else => {},
                }
            }

            // std.debug.print("hmm {d} chmm {d}\n", .{ self.idx_x, self.idx_z });
            const field_id = working_size.idx(self.idx_x, self.idx_z);
            const pos = grid_data.fields[field_id];
            self.debug_pos = pos;
            self.debug_pos[1] = 1;
            return math.asRlvec3(pos);
        }

        pub fn traverse(self: *Self, pamperek: *Player, move: Move) rl.Vector3 {
            const new_pos = self.decodeMove(move);
            self.phase = pamperek.cam_phase;

            return new_pos;
        }

        pub fn deinit(self: *Self) void {
            self.board.deinit();
        }

        fn navigDebug(self: *Self) void {
            const dirs: []const math.fvec3 = &.{
                Self.Forward,
                Self.Right,
                Self.Backward,
                Self.Left,
            };

            const origin = math.asRlvec3(self.debug_pos);
            const up = rl.Vector3.init(0, 1, 0);
            const mult: math.fvec3 = @splat(3);
            for (dirs) |dir| {
                const rlvec = math.asRlvec3(dir * mult);
                rl.drawLine3D(origin, origin.add(rlvec), rl.Color.maroon);
            }

            var osc_calc = Osc{ .phase = self.phase };
            const xz = osc_calc.sample2D();
            const rlxz = rl.Vector3.init(xz[0], 0, xz[1]).scale(-1);
            const xz_origin = origin.add(up.scale(0.5));
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
            const sim_origin = origin.add(up.scale(0.25));
            const aligned = math.asRlvec3(dirs[max_id]);
            rl.drawLine3D(sim_origin, sim_origin.add(aligned), rl.Color.pink);
        }

        pub fn repr(self: *Self) void {
            self.board.board.repr();
            self.navigDebug();
        }
    };
}
