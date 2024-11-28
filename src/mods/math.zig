pub const vi2 = @Vector(2, i32);
pub const vf2 = @Vector(2, f32);

pub fn u2f(a: u32) f32 {
    return @as(f32, @floatFromInt(a));
}

pub fn u2i(a: u32) i32 {
    return @as(i32, @intCast(a));
}

pub fn f2i(a: f32) i32 {
    return @as(i32, @intFromFloat(a));
}

pub fn calcProgres(i: u32, n: u32, closed: bool) f32 {
    const dol = if (closed) n - 1 else n;
    return u2f(i) / u2f(dol);
}
