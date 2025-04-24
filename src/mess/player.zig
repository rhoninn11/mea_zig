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
    const JumpState = enum {
        ground,
        launching,
        air,
        landing,
    };

    pos: rl.Vector3,
    camera: rl.Camera,
    colider: Sphere,
    osc: Osc = Osc{},

    text: [64:0]u8 = undefined,
    cursor: u8 = 0,

    ground_level: f32 = 0,
    jump_level: f32 = 0,
    jump_state: JumpState = .ground,
    jump_speed: f32 = 0,

    move_dir: rl.Vector3,

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
            .move_dir = rl.Vector3.zero(),
        };
        @memset(p.text[0..p.text.len], 0);
        return p;
    }

    pub fn deinit(self: *Player) void {
        std.debug.print("for now player dont need to deinit but it w8:D\n", .{});
        _ = self;
    }

    inline fn inputText(self: *Player) void {
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

    inline fn inputJump(self: *Player) void {
        const jumpKey = rl.KeyboardKey.space;
        const jump_action = rl.isKeyPressed(jumpKey);
        if (jump_action and self.jump_state == .ground) {
            self.jump_state = .launching;
        }
    }

    inline fn inputMove(self: *Player) void {
        const front = rl.Vector3.init(1, 0, 0);
        const right = rl.Vector3.init(0, 0, 1);
        const move_key_v = [_]rl.KeyboardKey{
            rl.KeyboardKey.w,
            rl.KeyboardKey.s,
            rl.KeyboardKey.a,
            rl.KeyboardKey.d,
        };
        const move_dir_v = [_]rl.Vector3{
            front,
            front.scale(-1),
            right.scale(-1),
            right,
        };

        var is_moving = false;
        var move_dir: rl.Vector3 = rl.Vector3.zero();
        for (move_dir_v, move_key_v) |dir, key| {
            if (rl.isKeyDown(key)) {
                is_moving = true;
                move_dir = dir;
                std.debug.print("move prepared with {s}\n", .{@tagName(key)});
            }
        }

        self.move_dir = if (is_moving) move_dir else rl.Vector3.zero();
    }

    inline fn moveCamera(self: *Player, dt: f32) void {
        const hight: f32 = 5;
        const away: f32 = 7;
        self.osc.freq = 0.2 / (away);
        const awayV: math.fvec2 = @splat(away);

        self.osc.update(dt);
        const xz = self.osc.sample2D() * awayV;

        const zero = rl.Vector3.zero();
        self.camera.target = zero;
        self.camera.position = rl.Vector3.init(xz[0], hight, xz[1]);
    }

    inline fn moveSpatial(self: *Player) void {
        self.pos = self.move_dir;
        self.pos.y = self.jump_level;
    }
    fn simJump(self: *Player, dt_ms: f32) void {
        const dt_s = dt_ms * 0.001;
        const acc = 10;
        switch (self.jump_state) {
            .launching => {
                self.jump_state = .air;
                self.jump_speed = 10;
                std.log.debug("+++ launching", .{});
            },
            .air => {
                self.jump_speed = self.jump_speed - acc * dt_s;
            },
            .landing => {
                self.jump_state = .ground;
                self.jump_speed = 0;
                self.jump_level = self.ground_level;
                std.log.debug("+++ landing", .{});
            },
            .ground => {},
        }

        switch (self.jump_state) {
            .air => {
                self.jump_level += self.jump_speed * dt_s;
                std.log.debug("+++ in air: {d: <4}\n", .{self.jump_level});
                if (self.jump_level <= self.ground_level) {
                    self.jump_state = .landing;
                }
            },
            else => {},
        }
    }

    pub fn update(self: *Player, dt: f32) void {
        self.inputText();
        self.inputJump();
        self.inputMove();
        self.simJump(dt);
        self.moveCamera(dt);
        self.moveSpatial();

        // ##### pre camera manipulation
        // const cam = &self.camera;
        // rl.updateCamera(cam, .third_person);
        // self.pos = cam.target;

        // colide update
        self.colider.pos = math.asRelVec3(self.pos);
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

    pub fn moveInput() void {}
};
