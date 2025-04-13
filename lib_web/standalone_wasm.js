

var memory = new WebAssembly.Memory({
    initial: 2,
    maximum: 2,
});


// Attmept to acces microphone data on zig side over browser api
// Refs:
//      https://developer.mozilla.org/en-US/docs/Web/API/AnalyserNode
const mediaDevices = navigator.mediaDevices;
const audioRequest = {
  audio: true,
};
class MicAccess {
    analyser = null;
    audio_buffer = null;
    animation_frame = null;

    info = () => {
        console.log(`+++ MicroAccess state: alive ${this.alive}`);
    };
}
const micAccess = new MicAccess();
micAccess.info()

const micInit = () => {
    mediaDevices.enumerateDevices()
        .then((devices) => console.log(devices));
    mediaDevices.getUserMedia(audioRequest)
        .then((stream) => plugAudio(stream));
}

const onAudioData = () => {
    const buffer = micAccess.audio_buffer;
    micAccess.analyser.getByteTimeDomainData(buffer);
    var max = -100000;
    var min = 100000;
    for(var i = 0; i < buffer.length; i++){
        const sample = buffer[i];
        if(sample > max ) max = sample;
        if(sample < min ) min = sample;
    }
    micAccess.animation_frame = requestAnimationFrame(onAudioData);
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
    
    
    micAccess.alive = true;
    micAccess.analyser = analyser;
    micAccess.audio_buffer = audio_buffer;
    micAccess.info();

    onAudioData();
}

const js_bridge = {
    env: {
        memory,
        consoleLog: (ptr, len) => {
            const text = new TextDecoder().decode(new Uint8Array(memory.buffer, ptr, len));
            console.log(text);
        },
        initRecording: micInit 
    }
}


fetch("bin/fns.wasm").then(zig_lib => {
    WebAssembly.instantiateStreaming(zig_lib, js_bridge)
        .then((wasm_module) => {
            console.log("+++ wasm from zig loaded");
            const zig = wasm_module.instance.exports;
            const zig_callFromVm = zig.callFromVm;
            const zig_wasmLog = zig.vmLog;

            let reaction = new TextEncoder().encode("+++ Santa Clouse was touched reading words of that guy")
            zig_wasmLog(reaction.buffer, reaction.byteLength);
        })
});


const Pretext = "none";
export default Pretext;