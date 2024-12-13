


var memory = new WebAssembly.Memory({
    initial: 2,
    maximum: 2,
});


const bridge = {
    env: {
        memory,
        consoleLog: (ptr, len) => {
            const text = new TextDecoder().decode(new Uint8Array(memory.buffer, ptr, len));
            console.log(text);
        }
    }
}


fetch("bin/fns.wasm").then(modul => {
    WebAssembly.instantiateStreaming(modul, bridge)
    .then((module) => {
        const callFromVm = module.instance.exports.callFromVm;
        const vmLog = module.instance.exports.callFromVm;
    
        let reaction = new TextEncoder().encode("+++ Santa Clouse was touched reading words of that guy")
        vmLog(reaction.buffer, reaction.byteLength);
    })
});


const Pretext = "none";
export default Pretext;