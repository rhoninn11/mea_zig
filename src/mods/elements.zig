const std = @import("std");
const rl = @import("raylib");
const math = @import("core/math.zig");
const input = @import("input.zig");

const repr = @import("core/repr.zig");

const vf2 = math.fv2;

pub const Exiter = struct {
    const Self = @This();
    pos: math.fv2,
    key: input.KbKey,
    sigRef: *input.Signal,
    trig_delay: input.Delay,
    exit_delay: input.Delay,

    size: f32,
    const minSize: f32 = 50;
    const deltaSize: f32 = 1;

    pub fn spawn(at: math.fv2, with: rl.KeyboardKey) Self {
        const key = input.KbKey.init(with, 0);
        var mock = input.Signal{};
        const trig_delay = input.Delay{ .to_track = &mock, .ms_delay = 350 };
        const exit_delay = input.Delay{ .to_track = &mock, .ms_delay = 600 };
        return Self{
            .pos = at,
            .key = key,
            .sigRef = &mock,
            .trig_delay = trig_delay,
            .exit_delay = exit_delay,
            .size = Self.minSize,
        };
    }

    pub fn selfReference(self: *Self) void {
        const sig = &self.key.hold.base;
        self.sigRef = sig;
        self.trig_delay.to_track = sig;
        self.exit_delay.to_track = self.trig_delay.sigRef();
    }

    pub fn collectInput(self: *Self) void {
        self.key.collectiInput();
    }

    pub fn update(self: *Self, delta_ms: f32) void {
        self.key.update(delta_ms);
        self.trig_delay.update(delta_ms);
        self.exit_delay.update(delta_ms);

        if (self.sigRef.get()) {
            self.size += Self.deltaSize;
        } else {
            self.size = if (self.size <= Self.minSize) Self.minSize else self.size - Self.deltaSize;
        }
    }

    pub fn draw(self: Self) void {
        repr.blob(self.pos, self.trig_delay.get(), self.size);
    }

    pub fn toContinue(self: Self) bool {
        const exitCond = self.exit_delay.get();
        return exitCond == false;
    }
};

pub fn GridSurface(x: u32, y: 32) type {
    return SurfaceInfo(x * y);
}

pub fn SurfaceInfo(n: u32) type {
    return _SurfaceInfo(n, repr.Tile);
}

pub fn SurfaceBasedOnFile(file: []const u8) type {
    const R = struct { p: u8 };
    _ = file;
    // hmmm, ciekawe czy mółbym sobie odczytać taki parametr z pliku
    // to może być jakiś json, albo plik systemu, który udaje json xD
    return R;
}

fn _SurfaceInfo(n: u32, kind_of: type) type {
    const sz = @sizeOf(kind_of);
    std.debug.assert(sz <= 64);
    // @compileLog("!!! For assert validation if compile fail !!! ", n);
    std.debug.assert(n <= 256);

    return struct {
        const Self = @This();
        const rows = 32;
        const cols = n / Self.rows;

        // tiles: [n]repr.Tile,
        tiles: [n]kind_of = undefined,

        pub fn draw(self: *Self) void {
            for (&self.tiles) |*tile| repr.tBlob(tile.*);
        }

        pub fn benchGrid(self: *Self, size: math.fv2) void {
            const Rand = std.rand.DefaultPrng;
            var _rng = Rand.init(0);
            var rng = _rng.random();

            const rowspace = 1.0 / @as(f32, @floatFromInt(Self.rows));
            const colspace = 1.0 / @as(f32, @floatFromInt(Self.cols));

            for (0..n) |i| {
                const x = @as(f32, @floatFromInt(i / Self.rows)) * colspace;
                const y = @as(f32, @floatFromInt(@mod(i, Self.rows))) * rowspace;

                var tile: *repr.Tile = &self.tiles[i];
                tile.pos = vf2{ x, y } * size;
                tile.size = y * 15 + 5;
                tile.color = rl.Color.fromHSV(rng.float(f32) * 10, rng.float(f32), rng.float(f32));
            }
        }
    };
}
