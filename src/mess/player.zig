// const input = @import("input.zig");
const math = @import("math.zig");
const rl = @import("raylib");
const view = @import("view.zig");
const collision = @import("sphere.zig");

const Sphere = collision.Sphere;

pub const Player = struct {
    pos: rl.Vector3,
    camera: rl.Camera,
    sphere: Sphere,

    pub fn init() Player {
        var cam = view.cameraPersp();
        rl.updateCamera(&cam, .camera_third_person);
        return Player{
            .camera = cam,
            .pos = cam.target,
            .sphere = Sphere{
                .pos = math.asRelVec3(cam.target),
                .size = 0.3,
            },
        };
    }

    pub fn update(self: *Player) void {
        const cam = &self.camera;
        rl.updateCamera(cam, .camera_third_person);
        const shared_pos = cam.target;
        self.sphere.pos = math.asRelVec3(shared_pos);
        self.pos = shared_pos;
    }

    pub fn drawSphere(self: *Player, color: rl.Color) void {
        rl.drawSphere(self.pos, self.sphere.size, color);
    }

    // TODO: what i want to implement here is custom implementation of 3d movement
    // additional moves like jump or camera paninng with mouse
};
