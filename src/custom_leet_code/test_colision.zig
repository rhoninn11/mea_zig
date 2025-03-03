// Oto zadanie typu LeetCode, które łączy podstawowe algorytmy z elementami symulacji 3D, idealnie nadające się do ćwiczenia Ziga:

// ### Kolizja obiektów 3D
// ## Treść zadania

// Napisz funkcję w języku Zig, która wykrywa kolizję między dwoma sferami w przestrzeni 3D.
// Każda sfera jest reprezentowana przez swoją pozycję (x, y, z) oraz promień r. Dwie sfery kolidują ze sobą, jeśli odległość między ich środkami jest mniejsza lub równa sumie ich promieni.
// Dodatkowo, funkcja powinna zwracać wektor przesunięcia (displacement vector) potrzebny do rozdzielenia sfer, jeśli kolidują.

const fvec3 = @Vector(3, f32);

const Sphere = struct {
    size: f32,
    pos: fvec3,

    pub fn qSize(sphere: Sphere) f32 {
        return sphere.size * sphere.size;
    }
};

const TachinState = enum {
    far,
    close,
    touching,
};

fn tachin(one: Sphere, second: Sphere) TachinState {
    const delta = second.pos - one.pos;
    const dist = delta[0] * delta[0] + delta[1] * delta[1] + delta[2] * delta[2];

    const size_cond = one.qSize() * second.qSize();

    if (dist > size_cond) {
        return TachinState.far;
    } else {
        return TachinState.touching;
    }
}

const std = @import("std");
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
    // var perf_timer = try std.time.Timer.start();
    // const total: u64 = K * K;
    // for (0..total) |_| {
    //     _ = tachin(a, b);
    // }
    // const ns = perf_timer.lap();
    // try std.testing.expect(ns < K * K * 100);
    // 1M collisions under 100 ms
}
