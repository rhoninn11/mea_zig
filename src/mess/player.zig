// const input = @import("input.zig");
const math = @import("math.zig");
const rl = @import("raylib");
const view = @import("view.zig");

pub const Player = struct {
    pos: rl.Vector3,
    camera: rl.Camera,

    pub fn init() Player {
        var cam = view.cameraPersp();
        rl.updateCamera(&cam, .camera_third_person);

        return Player{
            .camera = cam,
            .pos = cam.target,
        };
    }

    pub fn update(self: *Player) void {
        const cam = &self.camera;
        rl.updateCamera(cam, .camera_third_person);
    }

    // TODO: what i want to implement here is custom implementation of 3d movement
    // additional moves like jump or camera paninng with mouse
};
