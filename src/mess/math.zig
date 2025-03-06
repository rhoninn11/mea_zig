const rl = @import("raylib");
pub const iv2 = @Vector(2, i32);
pub const fv2 = @Vector(2, f32);
pub const fvec3 = @Vector(3, f32);

pub inline fn fvec3Rl(ve3: fvec3) rl.Vector3 {
    return rl.Vector3.init(ve3[0], ve3[1], ve3[2]);
}
pub inline fn asRelVec3(ve3: rl.Vector3) fvec3 {
    return fvec3{ ve3.x, ve3.y, ve3.z };
}

pub fn i2f(a: i32) f32 {
    return @as(f32, @floatFromInt(a));
}

pub fn u2f(a: u32) f32 {
    return @as(f32, @floatFromInt(a));
}

pub fn u2i(a: u32) i32 {
    return @as(i32, @intCast(a));
}

pub fn f2i(a: f32) i32 {
    return @as(i32, @intFromFloat(a));
}

pub fn fviv(fv: fv2) iv2 {
    return iv2{ f2i(fv[0]), f2i(fv[1]) };
}

pub fn ivfv(iv: iv2) fv2 {
    return fv2{ i2f(iv[0]), i2f(iv[1]) };
}

pub fn calcProgres(i: u32, n: u32, closed: bool) f32 {
    const dol = if (closed) n - 1 else n;
    return u2f(i) / u2f(dol);
}

pub const axisX = fv2{ 1, 0 };
pub const axisY = fv2{ 0, 1 };
