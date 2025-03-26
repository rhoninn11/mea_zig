const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");

// w sumie to zapytełem się llma o jakieś zadanie
// aby było związne z gamedevem i

const Cube = struct {
    size: math.fvec3 = @splat(1),
    pos: math.fvec3 = @splat(0),
    // but i thing it also should have rotation
    // axis aligned box is special case
};

pub const Sphere = struct {
    size: f32 = 1,
    pos: math.fvec3 = @splat(0),
};
pub const TachinState = enum {
    far,
    close,
    touching,
};
const col_type = enum {
    ball,
    box,
};

pub const Colide = union(col_type) {
    ball: Sphere,
    box: Cube,

    fn asUnicode(self: Colide) []const u8 {
        switch (self) {
            .ball => return "🏀",
            .box => return "🧊",
        }
    }
};

fn quadraticR(s: *const Sphere) f32 {
    return s.size * s.size;
}

test "quadratic r" {
    var s1 = Sphere{
        .pos = @splat(0),
        .size = 1,
    };
    try std.testing.expectEqualDeep(1, quadraticR(&s1));
    s1.size = 0.5;
    try std.testing.expectEqual(0.25, quadraticR(&s1));
}

pub fn sphereTachin(one: Sphere, second: Sphere) TachinState {
    const delta = second.pos - one.pos;
    const q_dist = math.dot(delta, delta);

    const q_size_sum = quadraticR(&one) + quadraticR(&second);
    // std.debug.print("+++ qsize {d}, qdist {d}\n", .{ q_size_sum, q_dist });
    // std.time.sleep(1 * std.time.ns_per_s);

    if (q_size_sum > q_dist) {
        return TachinState.touching;
    } else {
        return TachinState.far;
    }
}
pub fn cubeSphereTachin(one: Cube, second: Sphere) TachinState {
    _ = one;
    _ = second;
    // idono which strategy to sellect

    return TachinState.far;
}
pub fn cubeCubeTachin(one: Cube, second: Cube) TachinState {
    _ = one;
    _ = second;

    return TachinState.far;
}

const a = Sphere{ .size = 1, .pos = .{ 0, 0, 2 } };
const b = Sphere{ .size = 0.5, .pos = .{ 0, 0, 0 } };
const c = Cube{ .size = @splat(1), .pos = @splat(0) };
const d = Cube{ .size = @splat(1), .pos = .{ 0, 0, 2 } };

test "touching test" {
    const ab = sphereTachin(a, b);
    try std.testing.expect(ab == .far);
    const aa = sphereTachin(a, a);
    try std.testing.expect(aa == .touching);
    const ac = cubeSphereTachin(c, a);
    try std.testing.expect(ac == .touching);
}

const K = 1024;

test "cubes tauching" {}

fn populateSpheresRandom(shperes: []Sphere, indices: []@Vector(2, usize)) void {
    var rand = std.rand.DefaultPrng.init(0);
    for (shperes) |*test_point| {
        const x = rand.random().floatNorm(f32);
        const y = rand.random().floatNorm(f32);
        const z = rand.random().floatNorm(f32);
        const size = rand.random().floatNorm(f32);

        test_point.pos = .{ x, y, z };
        test_point.size = size;
    }

    for (indices) |*indice| {
        indice[0] = rand.random().intRangeLessThan(usize, 0, K);
        indice[1] = rand.random().intRangeLessThan(usize, 0, K);
    }
}

test "tachin performance test" {
    try messure_pref();
    try std.testing.expect(true);
}

fn messure_pref() !void {
    const ms = std.time.ns_per_ms;
    const ind_type = @Vector(2, usize);
    const alo = std.testing.allocator;
    const data = try alo.alloc(Sphere, K);
    const inds = try alo.alloc(ind_type, K);
    defer alo.free(data);
    defer alo.free(inds);

    populateSpheresRandom(data, inds);
    var messure_span = try std.time.Timer.start();
    var count: u32 = 0;
    while (messure_span.read() < ms * 100) {
        for (0..K) |i| {
            const from = inds[@mod(i, K)];
            _ = sphereTachin(data[from[0]], data[from[1]]);
        }
        count += 1;
    }
    const colide = Colide{ .ball = Sphere{} };
    const icon = Colide.asUnicode(colide);
    std.debug.print("+++ {s}x{s} - {d}K in 1 s", .{ icon, icon, count * 10 });
}
