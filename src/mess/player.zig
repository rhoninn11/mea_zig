const std = @import("std");
const rl = @import("raylib");
const math = @import("math.zig");
const view = @import("view.zig");
const collision = @import("sphere.zig");
const phys = @import("phys.zig");
const sound = @import("sound.zig");

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

//Czyli "Co o konceptach można myśleć w taki bardziej abstrakcyjny sposób?"
//Nie mniej jednak w tym edytorze mógłoby się przydać jakieś ui:D
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

pub const Modes = enum {
    navig,
    edit,
    no_turn,
};

pub const JumpState = enum {
    ground,
    launching,
    air,
    landing,
};

const d_default = @import("dubble.zig").default;
const PlayerUI = struct {
    const Self = @This();

    texts: [4][]const u8 = .{
        "jeden", "dwa", "trzy", "cztery",
    },
    width: f32 = 100,
    height: f32 = 100,

    pub fn repr(self: *Self, p1: *Player) void {
        const general_theme = @import("repr.zig").theme;
        const border = self.width * 0.2;
        const num = self.texts.len;
        const total_w = self.width * num + border * (num + 1);
        const total_h = self.height + border * 2;

        const pos: math.ivec2 = .{ 0, 0 };
        const size: math.ivec2 = .{ @intFromFloat(total_w), @intFromFloat(total_h) };
        d_default.rect.repr(pos, size, general_theme);

        for (0..num) |i| {
            const i_float: f32 = @floatFromInt(i);
            const x_pos: f32 = border + i_float * (border + self.width);
            const frag_pos: math.ivec2 = .{ @intFromFloat(x_pos), @intFromFloat(border) };
            const frag_size: math.ivec2 = .{ @intFromFloat(self.width), @intFromFloat(self.height) };
            d_default.rect.repr(frag_pos, frag_size, general_theme);
        }

        d_default.text.repr(p1.text[0..64], pos, 24, general_theme);
    }
};

pub const Player = struct {
    const Self = @This();
    ui: PlayerUI = PlayerUI{},

    pos: rl.Vector3,
    pos_physin: rl.Vector3 = undefined,
    pos_physout: rl.Vector3 = undefined,
    pos_phys: Inertia3D = Inertia3D.zero(Cfg3D.default()),

    camera: rl.Camera,
    colider: Sphere,
    osc: Osc = Osc{},

    text: [64:0]u8 = undefined,
    cursor: u8 = 0,

    spots: [16]rl.Vector3 = undefined,
    spot_num: u8 = 0,
    spot_ptr: u8 = 0,

    ground_level: f32 = 0,
    jump_level: f32 = 0,
    jump_state: JumpState = .ground,
    jump_speed: f32 = 0,

    move_action: Move = Move.no_move,
    cam_target: rl.Vector3 = Rlvec3{ .x = 0, .y = 0, .z = 0 },
    cam_inert_targ: Inertia3D = Inertia3D.zero(Cfg3D.default()),

    cam_phase: f32 = math.PI,
    cam_inert_phase: Inertia1D = Inertia1D.zero(Cfg1D.default()),

    world: ?*World = null,
    editor: Editor = Editor{},
    operation_mode: Modes = Modes.navig,

    pub fn init() Player {
        var cam = view.cameraPersp();
        rl.updateCamera(&cam, .third_person);

        var p1 = Player{
            .camera = cam,
            .pos = cam.target,
            .pos_physout = cam.target,
            .pos_physin = cam.target,
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

    const Unicode = extern union {
        as_rune: i32,
        as_array: [4]u8,
    };
    fn processText(self: *Player, char: Unicode) void {
        if (self.cursor == self.text.len) {
            const full = self.text.len;
            const half = full / 2;
            @memcpy(self.text[0..half], self.text[half..full]);
            @memset(self.text[half..full], 0);
            self.cursor = half;
        }

        std.debug.print("+++ unicode? {}\n", .{char.as_rune});
        // assuming big

        // TODO: check if unicodes are properly handled
        for (char.as_array, 0..) |byte, i| {
            if (byte != 0x00) {
                std.debug.print("({d})", .{i});
                // WARN: while chars are unicodes cursor can espace memory
                self.text[self.cursor] = byte;
                self.cursor += 1;
            }
        }

        return;
    }

    fn inputText(self: *Player) void {
        while (true) {
            const code = rl.getCharPressed();
            if (code == 0) break;
            self.processText(Unicode{ .as_rune = code });
        }
    }

    fn inputJump(self: *Player) void {
        const jumpKey = rl.KeyboardKey.space;
        const jump_action = rl.isKeyPressed(jumpKey);
        if (jump_action and self.jump_state == .ground) {
            self.jump_state = .launching;
            self.spawnAction();
        }
    }

    fn inputBuild(self: *Player) void {
        const build_key = rl.KeyboardKey.space;
        const build_action = rl.isKeyPressed(build_key);
        if (build_action) {
            self.spawnAction();
            rl.playSound(sound.getBam().*);
        }
    }
    const MoveKey = struct {
        key: rl.KeyboardKey,
        move: Move,
    };

    const TurnAction = struct {
        key: rl.KeyboardKey,
        amount: f32,
    };

    fn inputMove(self: *Player) void {
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

    fn inputCameraTurn(self: *Player) void {
        const activationFn = rl.isKeyPressed;
        const move_set: []const TurnAction = &.{
            TurnAction{ .key = rl.KeyboardKey.h, .amount = 0.45 },
            TurnAction{ .key = rl.KeyboardKey.l, .amount = -0.45 },
        };

        for (move_set) |action| {
            if (activationFn(action.key)) {
                self.cam_phase = self.cam_phase + action.amount;
            }
        }
    }

    fn inputModeSwitch(self: *Player) void {
        const activationFn = rl.isKeyPressed;
        const kb = rl.KeyboardKey.tab;

        if (activationFn(kb)) {
            self.operation_mode = switch (self.operation_mode) {
                Modes.edit => Modes.navig,
                Modes.navig => Modes.edit,
                else => self.operation_mode,
            };
        }
    }

    fn spawnAction(self: *Player) void {
        const spawn_point = self.pos;
        self.spots[self.spot_ptr] = spawn_point;

        if (self.spot_num < self.spots.len) {
            self.spot_num += 1;
        }

        self.spot_ptr += 1;
        if (self.spot_ptr == self.spots.len) {
            self.spot_ptr = 0;
        }

        std.debug.print("spawned at {}\n", .{spawn_point});
    }

    fn simJump(self: *Player, dt_ms: f32) void {
        const dt_s = dt_ms * 0.001;
        const acc = 20;
        const initial_speed: comptime_float = 5;
        switch (self.jump_state) {
            .launching => {
                self.jump_state = .air;
                self.jump_speed = initial_speed;
                // std.log.debug("+++ launching", .{});
            },
            .air => {
                self.jump_speed = self.jump_speed - acc * dt_s;
            },
            .landing => {
                self.jump_state = .ground;
                self.jump_speed = 0;
                self.jump_level = self.ground_level;
                // std.log.debug("+++ landing", .{});
            },
            .ground => {},
        }

        switch (self.jump_state) {
            .air => {
                self.jump_level += self.jump_speed * dt_s;
                // std.log.debug("+++ in air: {d: <4}\n", .{self.jump_level});
                if (self.jump_level <= self.ground_level) {
                    self.jump_state = .landing;
                }
            },
            else => {},
        }
    }

    fn simCam(self: *Player, dt: f32) void {
        // while pos also has inetria camera do not need to be dumped
        // eventually could be faster - to not look wierd
        const new_targ_pos = math.asFvec3(self.pos);
        const inert_tg = &self.cam_inert_targ;
        inert_tg.in(new_targ_pos);
        inert_tg.simulate(dt);

        const inert_ph = &self.cam_inert_phase;
        inert_ph.in(.{self.cam_phase});
        inert_ph.simulate(dt);
        const delayed_phase = inert_ph.out();

        const away: f32 = 9;
        const hight: f32 = 3.51;
        const osc_calc = Osc{ .phase = delayed_phase[0] };
        const planar_pos = osc_calc.sample2D() * math.fvec2{ away, away };
        const new_cam_pos = rl.Vector3.init(planar_pos[0], hight, planar_pos[1]);
        var offset = self.pos;
        offset.y = 0;

        self.camera.target = self.pos;
        self.camera.position = new_cam_pos.add(offset);
    }

    fn moveSpatial(self: *Player) void {
        // Q: how now i have connection with board i could move on its fields
        // A: now world generate new position, where player will be placed on

        var world = self.world.?;
        const pos_next = world.traverse(self, self.move_action);
        self.pos_physin = pos_next;

        self.pos = self.pos_physout;
        self.pos.y = self.jump_level;
    }

    fn simMove(self: *Player, dt: f32) void {
        self.pos_phys.in(math.asFvec3(self.pos_physin));
        self.pos_phys.simulate(dt);
        self.pos_physout = math.asRlvec3(self.pos_phys.out());
    }

    pub fn update(self: *Player, dt: f32) void {
        self.inputModeSwitch();
        switch (self.operation_mode) {
            Modes.edit => self.inputText(),
            Modes.navig => {
                self.inputJump();
                self.inputBuild();
                self.inputMove();
                self.inputCameraTurn();
            },
            else => {},
        }
        self.simJump(dt);
        self.simMove(dt);
        self.moveSpatial();
        self.simCam(dt);

        // colide update
        self.colider.pos = math.asFvec3(self.pos);
    }

    pub fn repr(self: *Player, color: rl.Color) void {
        rl.drawSphere(self.pos, self.colider.size, color);
    }

    // FILO: czym są symulacje... to programy, które żyją własnym życiem?
    //       może trochę zależy też co symulują, ale zazwyczaj starają się
    //       przedstawić jakieś zjawiska, a czy gracz też mógłby być symulowany?
    //       //
    // TODO: Teraz chciałmym móc ustawiać zdjęcia na tej planszy
    //       //

    pub fn moveInput() void {}
};
