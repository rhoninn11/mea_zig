const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");
const view = @import("view.zig");
const collision = @import("sphere.zig");

const Osc = @import("osc.zig").Osc;
const Sphere = collision.Sphere;

const Dir = std.fs.Dir;
const File = std.fs.File;

// for saving momory on drive or meaby to reviwe it at comptime??
pub const EditorMemory = struct {
    const Self = @This();
    pub const Slots = 256;
    pub const Tpy: type = math.fvec3;

    placedObjects: []Tpy,
    slot: u8,
    // mask: u256,
    pub fn addNew(self: *Self, at: math.fvec3) void {
        self.placedObjects[self.slot] = at;
        self.slot += 1;
    }

    // to persist on a hard drive
    pub fn save(self: *Self) !void {
        const cwd = std.fs.cwd();
        const mock_data: []const u8 = "Hamburger";
        const editor_mem = Dir.WriteFileOptions{
            .sub_path = "fs/editor.mem",
            .data = mock_data,
            .flags = .{},
        };

        try cwd.writeFile(editor_mem);
        std.log.debug("+++ saving {s}\n", .{editor_mem.sub_path});
        _ = self;
    }

    // to continue session
    pub fn load(self: *Self) void {
        const data: []const u8 = "not loaded yet";
        std.debug.print("{s}\n", .{data});
        _ = self;
    }
};

pub const Player = struct {
    pos: rl.Vector3,
    camera: rl.Camera,
    colider: Sphere,
    osc: Osc = Osc{},

    text: [64:0]u8 = undefined,
    cursor: u8 = 0,

    pub fn init() Player {
        var cam = view.cameraPersp();
        rl.updateCamera(&cam, .third_person);
        var p = Player{
            .camera = cam,
            .pos = cam.target,
            .colider = Sphere{
                .pos = math.asRelVec3(cam.target),
                .size = 0.3,
            },
        };
        @memset(p.text[0..p.text.len], 0);
        return p;
    }

    pub fn deinit(self: *Player) void {
        std.debug.print("for now player dont need to deinit but it w8:D\n", .{});
        _ = self;
    }
    pub fn customCameraUpdate(self: *Player, dt: f32) void {
        const hight: f32 = 5;
        const away: f32 = 7;
        self.osc.freq = 0.2 / (away);
        const awayV: math.fvec2 = @splat(away);

        self.osc.update(dt);
        self.camera.target = rl.Vector3.zero();
        const xz = self.osc.sample2D() * awayV;
        self.camera.position = rl.Vector3.init(xz[0], hight, xz[1]);

        // self.camera.position

        // not yet implemented
        // unreachable;
    }

    pub fn input(self: *Player) void {
        while (true) {
            const code = rl.getCharPressed();
            if (code == 0) break;
            if (self.cursor == self.text.len) {
                const full = self.text.len;
                const half = full / 2;
                @memcpy(self.text[0..half], self.text[half..full]);
                @memset(self.text[half..full], 0);
                self.cursor = half;
                std.debug.print("+1\n", .{});
            }

            //but polish characters breaking it
            if (code < 256) {
                const char: u8 = @intCast(code);
                self.text[self.cursor] = char;
                self.cursor += 1;
            } else {
                std.debug.print("+++ there was one of special characters {}\n", .{code});
            }
        }
    }

    pub fn update(self: *Player, dt: f32) void {
        self.input();
        const cam = &self.camera;
        const ready = false;
        switch (ready) {
            true => self.customCameraUpdate(dt),
            false => rl.updateCamera(cam, .third_person),
        }
        const shared_pos = cam.target;
        self.colider.pos = math.asRelVec3(shared_pos);
        self.pos = shared_pos;
    }

    pub fn repr(self: *Player, color: rl.Color) void {
        rl.drawSphere(self.pos, self.colider.size, color);
    }

    // TODO: what i want to implement here is custom implementation of 3d movement.
    //       Adding moves like jump or camera paninng with mouse
    // TODO: czym są symulacje... to programy, które żyją własnym życiem?
    //       może trochę zależy też co symulują, ale zazwyczaj starają się
    //       przedstawić jakieś zjawiska, a czy gracz też mógłby być symulowany
    //       //
};
