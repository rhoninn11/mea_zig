


var memory = new WebAssembly.Memory({
    initial: 2,
    maximum: 2,
});


class MicroAccess {
    alive = false;
    audio_stream = null;
    animation_frame = null;

    info = () => {
        console.log(`+++ MicroAccess state: alive ${this.alive}`);
    };
}

const libMemo = new MicroAccess();
libMemo.info()

const opWithAudioStream = (stream) => {
    libMemo.alive = true;
    libMemo.audio_stream = stream;
    libMemo.info();

    const audio_ctx = new AudioContext();
    const analyser = audio_ctx.createAnalyser();
    const source = audio_ctx.createMediaStreamSource(stream);

    analyser.fftSize = 2048;
    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    const update_fn = () => {
        analyser.getByteTimeDomainData(dataArray);
        const currentVolume = dataArray.reduce((acc, val) => acc + Math.abs(val - 128), 0) / dataArray.length;
        console.log(`this frame volume is: ${currentVolume}`);
        libMemo.animation_frame = requestAnimationFrame(update_fn);
    }
    console.log("+++ first update");
    update_fn()

}

const bridge = {
    env: {
        memory,
        consoleLog: (ptr, len) => {
            const text = new TextDecoder().decode(new Uint8Array(memory.buffer, ptr, len));
            console.log(text);
        },
        initRecording: () => {
            navigator.mediaDevices.getUserMedia({ audio: true })
                .then(opWithAudioStream)
        }
    }
}


fetch("bin/fns.wasm").then(modul => {
    WebAssembly.instantiateStreaming(modul, bridge)
        .then((module) => {
            console.log("+++ wasm from zig loaded");

            const callFromVm = module.instance.exports.callFromVm;
            const vmLog = module.instance.exports.vmLog;

            let reaction = new TextEncoder().encode("+++ Santa Clouse was touched reading words of that guy")
            vmLog(reaction.buffer, reaction.byteLength);
        })
});


const Pretext = "none";
export default Pretext;