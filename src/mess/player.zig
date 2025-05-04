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

//Cyli co o konceptach można myśleć w taki bardziej abstrakcyjny sposób
pub const Editor = struct {
    const Self = @This();
    memory: ?*EditorMemory = null,
    world: ?*World = null,

    pub fn placeConcept(self: *Self, player: *Player) void {
        //write something write concept in memory

        const pos = player.pos;
        const world = self.world.? orelse unreachable;

        _ = pos;
        _ = world;
    }
};

const Rlvec3 = rl.Vector3;

const _phys3D = phys.InertiaPack(math.fvec3);
const Cfg3D = _phys3D.InertiaCfg;
const Inertia3D = _phys3D.Inertia;
const _phys1D = phys.InertiaPack(@Vector(1, f32));
const Cfg1D = _phys1D.InertiaCfg;
const Inertia1D = _phys1D.Inertia;

const Allocator = std.mem.Allocator;
pub const World = boards.WorldNavigBoard();

pub const Move = enum {
    up,
    down,
    left,
    right,
    no_move,
};

pub const TurnCamera = enum {
    turn_left,
    turn_right,
    no_turn,
};

pub const JumpState = enum {
    ground,
    launching,
    air,
    landing,
};

pub const Player = struct {
    const Self = @This();

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
    cam_inert_targ: Inertia3D = Inertia3D{
        .x = @splat(0),
        .y = @splat(0),
        .phx = Cfg3D.default(),
    },
    cam_phase: f32 = 0,
    cam_inert_phase: Inertia1D = .{
        .x = .{0},
        .y = .{0},
        .phx = Cfg1D.default(),
    },
    world: ?*World = null,
    editor: Editor = Editor{},

    pub fn init() Player {
        var cam = view.cameraPersp();
        rl.updateCamera(&cam, .third_person);

        var p1 = Player{
            .camera = cam,
            .pos = cam.target,
            .colider = Sphere{
                .pos = math.asFvec3(cam.target),
                .size = 0.3,
            },
        };
        @memset(p1.text[0..p1.text.len], 0);
        return p1;
    }

    pub fn addToTheWorld(self: *Self, world: *World) void {
        self.world = world;
        self.editor.world = world;
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

    const MoveKey = struct {
        key: rl.KeyboardKey,
        move: Move,
    };

    const TurnAction = struct {
        key: rl.KeyboardKey,
        turn: TurnCamera,
        amount: f32,
    };

    inline fn inputMove(self: *Player) void {
        const activationFn = rl.isKeyPressed;
        const move_set: []const MoveKey = &[_]MoveKey{
            MoveKey{ .key = rl.KeyboardKey.w, .move = Move.up },
            MoveKey{ .key = rl.KeyboardKey.s, .move = Move.down },
            MoveKey{ .key = rl.KeyboardKey.a, .move = Move.left },
            MoveKey{ .key = rl.KeyboardKey.d, .move = Move.right },
        };

        var selected: Move = .no_move;
        for (move_set) |control| {
            if (activationFn(control.key)) {
                selected = control.move;
            }
        }
        self.move_action = selected;
    }

    inline fn inputCameraTurn(self: *Player) void {
        const activationFn = rl.isKeyPressed;
        const move_set: []const TurnAction = &.{
            TurnAction{
                .key = rl.KeyboardKey.h,
                .turn = TurnCamera.turn_right,
                .amount = 0.45,
            },
            TurnAction{
                .key = rl.KeyboardKey.l,
                .turn = TurnCamera.turn_left,
                .amount = -0.45,
            },
        };

        var selected = TurnCamera.no_turn;
        for (move_set) |action| {
            if (activationFn(action.key)) {
                self.cam_phase = self.cam_phase + action.amount;
                selected = action.turn;
            }
        }
    }

    inline fn moveSpatial(self: *Player) void {
        // Q: how now i have connection with board i could move on its fields
        // A: now world generate new position, where player will be placed on

        var world = self.world.?;
        world.navig(self, self.move_action);
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

    fn simCam(self: *Player, dt: f32) void {
        const new_targ_pos = math.asFvec3(self.pos);
        const inert_tg = &self.cam_inert_targ;
        inert_tg.setTarget(new_targ_pos);
        inert_tg.simulate(dt);

        const inert_ph = &self.cam_inert_phase;
        inert_ph.setTarget(.{self.cam_phase});
        inert_ph.simulate(dt);
        const delayed_phase = inert_ph.getResutl();

        const away: f32 = 9;
        const hight: f32 = 3.51;
        const osc_calc = Osc{ .phase = delayed_phase[0] };
        const planar_pos = osc_calc.sample2D() * math.fvec2{ away, away };
        const new_cam_pos = rl.Vector3.init(planar_pos[0], hight, planar_pos[1]);

        self.camera.target = math.asRlvec3(inert_tg.getResutl());
        self.camera.position = new_cam_pos;
    }

    pub fn update(self: *Player, dt: f32) void {
        self.inputText();
        self.inputJump();
        self.inputMove();
        self.simJump(dt);
        self.moveSpatial();
        self.inputCameraTurn();
        self.simCam(dt);

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
