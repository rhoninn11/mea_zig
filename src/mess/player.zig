const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");
const view = @import("view.zig");
const collision = @import("sphere.zig");
const phys = @import("../mods/phys.zig");

const boards = @import("boards.zig");
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

const Rlvec3 = rl.Vector3;
const p = phys.InertiaPack(math.fvec3);
const Cfg = p.InertiaCfg;
const Inertia = p.Inertia;
const Allocator = std.mem.Allocator;

pub const World = boards.NavigationBoard();
pub const Player = struct {
    const Move = enum {
        up,
        down,
        left,
        right,
        no_move,

        fn vec(self: Move) rl.Vector3 {
            // TODO Doszedłem do takiego wniosku, że dobrze by było zmieniać kierunek wraz z obrotem kamery
            //      no bo jak teraz ta kamera tak sobie orbituje, to gdy kąt już zmieni się wystarczająco
            //      kierunki zaczynają się nieintuicyjnie dla użytkownika zmieniać
            //
            const z_ax = rl.Vector3.init(0, 0, 1);
            const x_ax = rl.Vector3.init(1, 0, 0);
            const zero = rl.Vector3.zero();
            return switch (self) {
                .up => z_ax,
                .down => z_ax.scale(-1),
                .left => x_ax.scale(-1),
                .right => x_ax,
                .no_move => zero,
            };
        }
    };
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

    move_action: Move = Move.no_move,
    cam_target: Rlvec3 = Rlvec3{ .x = 0, .y = 0, .z = 0 },
    cam_inert: Inertia = Inertia{
        .x = @splat(0),
        .y = @splat(0),
        .phx = Cfg.default(),
    },
    worlds: ?[]World = null,

    pub fn init(alloc: Allocator) !Player {
        var cam = view.cameraPersp();
        rl.updateCamera(&cam, .third_person);
        const worlds = alloc.alloc(World, 1) catch unreachable;
        for (worlds) |*world| {
            world.* = World.init(alloc) catch unreachable;
        }

        var p1 = Player{
            .camera = cam,
            .pos = cam.target,
            .colider = Sphere{
                .pos = math.asFvec3(cam.target),
                .size = 0.3,
            },
            .worlds = worlds,
        };
        @memset(p1.text[0..p1.text.len], 0);
        return p1;
    }

    pub fn deinit(self: *Player) void {
        // is it good idea for world to store allocator?zs
        if (self.worlds) |worlds| {
            var alloc: Allocator = undefined;
            defer alloc.free(worlds);
            for (worlds) |*world| {
                alloc = world.alloc;
                world.deinit();
            }
        }
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

    const MoveSet = struct {
        key: rl.KeyboardKey,
        move: Move,
    };

    inline fn inputMove(self: *Player) void {
        var direction: Move = .no_move;
        const move_set_v: []const MoveSet = &[_]MoveSet{
            MoveSet{ .key = rl.KeyboardKey.w, .move = Move.up },
            MoveSet{ .key = rl.KeyboardKey.s, .move = Move.down },
            MoveSet{ .key = rl.KeyboardKey.a, .move = Move.left },
            MoveSet{ .key = rl.KeyboardKey.d, .move = Move.right },
        };

        const activationFn = rl.isKeyPressed;
        for (move_set_v) |move| {
            if (activationFn(move.key)) {
                std.debug.print("halo\n", .{});
                direction = move.move;
            }
        }
        self.move_action = direction;
    }

    inline fn moveCamera(self: *Player, dt: f32) void {
        const hight: f32 = 3.51;
        const away: f32 = 9;
        self.osc.freq = 0.2 / (away);
        const awayV: math.fvec2 = @splat(away);

        self.osc.update(dt);
        const xz = self.osc.sample2D() * awayV;

        // const zero = rl.Vector3.zero();
        self.camera.target = self.cam_target;
        self.camera.position = rl.Vector3.init(xz[0], hight, xz[1]);
    }

    const quedra = math.quadra;
    inline fn moveSpatial(self: *Player) void {
        const delta = Move.vec(self.move_action);
        const next_pos = self.pos.add(delta);
        var world = &self.worlds.?[0];
        if (world.allowMove(next_pos)) {
            self.pos = next_pos;
        }

        self.pos.y = self.jump_level;
        const v_pos = math.asFvec3(self.pos);
        self.cam_inert.setTarget(v_pos);
        const v_targ = math.asRlvec3(self.cam_inert.getPos());
        self.cam_target = v_targ;
        // how now i have connection with board i could move on its fields
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
        self.cam_inert.simulate(dt);
        self.moveCamera(dt);
        self.moveSpatial();

        // ##### pre camera manipulation
        // const cam = &self.camera;
        // rl.updateCamera(cam, .third_person);
        // self.pos = cam.target;

        // colide update
        self.colider.pos = math.asFvec3(self.pos);
    }

    pub fn repr(self: *Player, color: rl.Color) void {
        rl.drawSphere(self.pos, self.colider.size, color);
    }

    // TODO: what i want to implement here is custom implementation of 3d movement.
    //       Adding moves like jump or camera paninng with mouse
    // TODO: czym są symulacje... to programy, które żyją własnym życiem?
    //       może trochę zależy też co symulują, ale zazwyczaj starają się
    //       przedstawić jakieś zjawiska, a czy gracz też mógłby być symulowany?
    //       //

    pub fn moveInput() void {}
};
