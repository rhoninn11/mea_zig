const std = @import("std");
const rl = @import("raylib");
const fvec3 = @import("../mess/math.zig").fvec3;

// w sumie to zapytełem się llma o jakieś zadanie
// aby było związne z gamedevem i

const Colider = union(enum) {
    sphere: Sphere,
    cube: Cube,
};

const Cube = struct {
    size: fvec3,
    pos: fvec3,
};

pub const TachinState = enum {
    far,
    close,
    touching,
};

pub const Sphere = struct {
    size: f32,
    pos: fvec3,

    pub fn rlPos(s: Sphere) rl.Vector3 {
        return rl.Vector3.init(s.pos[0], s.pos[1], s.pos[2]);
    }
};

fn quadraticR(s: *const Sphere) f32 {
    return s.size * s.size;
}

pub fn tachin(one: Sphere, second: Sphere) TachinState {
    const delta = second.pos - one.pos;
    const dist = delta[0] * delta[0] + delta[1] * delta[1] + delta[2] * delta[2];

    const size_cond = quadraticR(&one) + quadraticR(&second);

    if (dist > size_cond) {
        return TachinState.far;
    } else {
        return TachinState.touching;
    }
}

const a = Sphere{
    .size = 1,
    .pos = .{ 0, 0, 2 },
};

const b = Sphere{
    .size = 0.5,
    .pos = .{ 0, 0, 1 },
};
const K = 1024;

test "sphere touching" {
    const ab = tachin(a, b);
    try std.testing.expect(ab == .far);
    const aa = tachin(a, a);
    try std.testing.expect(aa == .touching);
}

test "tachin performance test" {
    var perf_timer = try std.time.Timer.start();
    const total: u64 = K * K;
    for (0..total) |_| {
        _ = tachin(a, b);
    }
    const ns = perf_timer.lap();
    try std.testing.expect(ns < K * K * 100);
    // 1M collisions under 100 ms
}
