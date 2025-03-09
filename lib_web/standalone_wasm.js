// https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode


var memory = new WebAssembly.Memory({
    initial: 2,
    maximum: 2,
});


class MicAccess {
    analyser = null;
    audio_buffer = null;
    animation_frame = null;

    info = () => {
        console.log(`+++ MicroAccess state: alive ${this.alive}`);
    };
}

const libMemo = new MicAccess();
libMemo.info()

const onAudioData = () => {
    const buffer = libMemo.audio_buffer;
    libMemo.analyser.getByteTimeDomainData(buffer);
    var max = -100000;
    var min = 100000;
    for(var i = 0; i < buffer.length; i++){
        const sample = buffer[i];
        if(sample > max ) max = sample;
        if(sample < min ) min = sample;
    }
    libMemo.animation_frame = requestAnimationFrame(onAudioData);
    // console.log(`+++ max value in stream: ${min} ${max} ${libMemo.animation_frame}`);
}

const plugAudio = (stream) => {
    const chunkSize = 2048;

    const audio_ctx = new window.AudioContext();
    const analyser = audio_ctx.createAnalyser();
    const mic_source = audio_ctx.createMediaStreamSource(stream);
    const audio_buffer = new Uint8Array(chunkSize/2);
    
    analyser.fftSize = chunkSize;
    mic_source.connect(analyser)
    analyser.getByteTimeDomainData(audio_buffer)
    
    
    libMemo.alive = true;
    libMemo.analyser = analyser;
    libMemo.audio_buffer = audio_buffer;
    libMemo.info();

    onAudioData();
}

const mediaDevices = navigator.mediaDevices;
const audioRequest = {
  audio: true,
};
const bridge = {
    env: {
        memory,
        consoleLog: (ptr, len) => {
            const text = new TextDecoder().decode(new Uint8Array(memory.buffer, ptr, len));
            console.log(text);
        },
        initRecording: () => {
            mediaDevices.enumerateDevices()
                .then((devices) => console.log(devices));

            mediaDevices.getUserMedia(audioRequest)
                .then((stream) => plugAudio(stream));
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