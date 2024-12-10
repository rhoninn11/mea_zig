


var memory = new WebAssembly.Memory({
    initial: 2,
    maximum: 2,
});

const bridge = {
    env: {
        consoleOutput: () => console.log("this is called from zig code"),
        memory
    }
}


var file_hmm = fetch("prebuilt/bin/fns.wasm");

WebAssembly.instantiateStreaming(file_hmm, bridge)
.then((module) => {
    const zig_fn = module.instance.exports.callFromVm;
    zig_fn()
})