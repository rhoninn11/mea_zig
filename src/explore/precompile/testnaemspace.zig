pub const Self = @This();

pub const Observer = struct { a: u8, b: u8 };

pub fn drawInsight(ob: *Observer) void {
    const aaa = ob.a;
    _ = aaa;
}

pub fn takeBreath(ob: *Observer) void {
    const bbb = ob.b;
    _ = bbb;
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

// pub const A = 12;
