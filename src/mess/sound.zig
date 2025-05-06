const std = @import("std");
const rl = @import("raylib");

const sound_file = "assets/bam.mp3";

var audio_inited: bool = false;

var loaded: bool = false;
var audio: rl.Sound = undefined;

pub fn getBam() *rl.Sound {
    if (!audio_inited) {
        rl.initAudioDevice();
        audio_inited = true;
    }

    if (!loaded) {
        audio = rl.loadSound(sound_file) catch unreachable;
        loaded = true;
    }

    return &audio;
}
