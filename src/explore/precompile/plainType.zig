pub const elo = enum { ene, due, rike, fake };

pub const obiekt = struct { a: u8, b: u8 };

pub fn act_I(ob: *obiekt) void {
    const a = ob.a;
    _ = a;
}

pub fn act_II(ob: *obiekt) void {
    const b = ob.b;
    _ = b;
}

pub const Module = @This();

pub const Nowomowa = enum {
    rel,
    essa,
    frl,
    ngl,
};
