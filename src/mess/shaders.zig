const std = @import("std");
const rl = @import("raylib");
const dbg = @import("debug.zig");

const ShaderTup = struct {
    vs: [:0]const u8,
    fs: [:0]const u8,
};

pub fn shaderFiles(comptime name: []const u8) ShaderTup {
    const shader_dir = "assets/shaders/";
    const vert = shader_dir ++ name ++ ".vs";
    const frag = shader_dir ++ name ++ ".fs";
    return ShaderTup{
        .vs = vert,
        .fs = frag,
    };
}

pub fn hasUniform(sh: rl.Shader, param_name: [:0]const u8, v: bool) bool {
    const yes = rl.getShaderLocation(sh, param_name) >= 0;
    if (v and !yes) std.debug.print("+++ {s} is missing\n", .{param_name});
    return yes;
}

pub fn hasUniforms(sh: rl.Shader, names: []const [:0]const u8, v: bool) bool {
    var ans = true;
    for (names) |name|
        ans = ans and hasUniform(sh, name, v);
    return ans;
}

pub const Paramatric = struct {
    const uniforms: []const [:0]const u8 = &.{
        "mvp",
        "texture0",
        "colDiffuse",
        "user_color",
        "user_mat",
    };
    shader: rl.Shader,
    model: rl.Model,

    pub fn init() !Paramatric {
        const vsfs = shaderFiles("param");
        var prefab = Paramatric{
            .shader = try rl.loadShader(vsfs.vs, vsfs.fs),
            .model = try rl.loadModel("assets/kostka.glb"),
        };
        prefab.model.materials[1].shader = prefab.shader;

        const has_all = hasUniforms(prefab.shader, Paramatric.uniforms, true);
        dbg.bypassAssert(has_all, false);
        // TODo: why this model uses mateial at index 1 not 0? I this model was exported from blender i think...
        return prefab;
    }

    pub fn deinit(self: Paramatric) void {
        rl.unloadShader(self.shader);
        rl.unloadModel(self.model);
    }

    pub fn repr(self: *const Paramatric, root: rl.Vector3) void {
        rl.drawModel(self.model, root, 1, rl.Color.blue);
    }
};
