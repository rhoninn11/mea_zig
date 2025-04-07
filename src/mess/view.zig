const std = @import("std");
const rl = @import("raylib");

const up = rl.Vector3.init(0, 1, 0);
const init = rl.Vector3.init(0, 1, -2);

pub fn cameraPersp() rl.Camera {
    return rl.Camera{
        .projection = .perspective,
        .fovy = 60,
        .up = up,
        .target = rl.Vector3.zero(),
        .position = init,
    };
}

pub fn cameraOrtho() rl.Camera {
    return rl.Camera{
        .projection = .orthographic,
        .fovy = 20,
        .up = up,
        .target = rl.Vector3.zero(),
        .position = init,
    };
}
