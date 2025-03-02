pub const Self = @This();

pub const Observer = struct { a: u8, b: u8 };

pub fn drawInsight(ob: *Observer) void {
    const a = ob.a;
    _ = a;
}

pub fn takeBreath(ob: *Observer) void {
    const b = ob.b;
    _ = b;
}
pub const Wyliczanka = enum {
    ene,
    due,
    rike,
    fake,
};

pub const Nowomowa = enum {
    essa,
    rel,
    frl,
    ngl,
};

pub const Bunch = union(enum) {
    of_one: Wyliczanka,
    of_two: Nowomowa,
};
