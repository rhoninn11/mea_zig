const std = @import("std");
const rl = @import("raylib");

const sound_file = "assets/bam.flac";

var loaded: bool = false;
var audio: rl.Sound = undefined;

pub fn getBam() *rl.Sound {
    if (!loaded) {
        audio = rl.loadSound(sound_file) catch unreachable;
        loaded = true;
    }

    return &audio;
}
