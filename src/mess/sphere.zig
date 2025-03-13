const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");

// w sumie to zapytełem się llma o jakieś zadanie
// aby było związne z gamedevem i

const Colider = union(enum) {
    sphere: Sphere,
    cube: Cube,
};

const Cube = struct {
    size: math.fvec3,
    pos: math.fvec3,
};

pub const TachinState = enum {
    far,
    close,
    touching,
};

pub const Sphere = struct {
    size: f32,
    pos: math.fvec3,
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
    // const q_dist = delta[0] * delta[0] + delta[1] * delta[1] + delta[2] * delta[2];
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

const a = Sphere{
    .size = 1,
    .pos = .{ 0, 0, 2 },
};

const b = Sphere{
    .size = 0.5,
    .pos = .{ 0, 0, 0 },
};
const K = 1024;

test "sphere touching" {
    const ab = sphereTachin(a, b);
    try std.testing.expect(ab == .far);
    const aa = sphereTachin(a, a);
    try std.testing.expect(aa == .touching);
}

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
    const ind_type = @Vector(2, usize);
    const data = try std.testing.allocator.alloc(Sphere, K);
    defer std.testing.allocator.free(data);
    const inds = try std.testing.allocator.alloc(ind_type, K);
    defer std.testing.allocator.free(inds);
    populateSpheresRandom(data, inds);

    var perf_timer = try std.time.Timer.start();
    const total: u64 = K * K;
    for (0..total) |i| {
        const from = inds[@mod(i, K)];
        _ = sphereTachin(data[from[0]], data[from[1]]);
    }
    const ns = perf_timer.lap();
    try std.testing.expect(ns < 100 * std.time.ns_per_ms);
    // 1M collisions under 100 ms
    // 9 ms with explicit mult, with perfect memory scenario | debug mode
    // 19 ms in more realistic scenario | debug mode
    // 19 ms using small vector in realistic scenario | debug mode

    std.debug.print("perf test pass in: {d} ms?\n", .{ns / std.time.ns_per_ms});
}
