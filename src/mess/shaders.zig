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

pub inline fn getLocation(sh: rl.Shader, param_anme: [:0]const u8) i32 {
    const loc = rl.getShaderLocation(sh, param_anme);
    std.debug.assert(loc >= 0);
    return loc;
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

pub const Form = enum {
    knot,
    cube,
};

const LocNameV: type = []const [:0]const u8;
const params_v1: LocNameV = &.{
    "mvp",
    "texture0",
    "colDiffuse",
    "user_color",
    "user_mat",
};

const params_v2: LocNameV = &.{
    "mvp",
    "user_color",
    "user_mat",
};

pub const Paramatric = VerionableShader(params_v1, "param");
// pub const Paramatric = VerionableShader(params_v2, "param_v2");
pub fn VerionableShader(locs: LocNameV, fileName: []const u8) type {
    return struct {
        const Self = @This();
        const Uniforms: LocNameV = locs;
        shader: rl.Shader,
        model: rl.Model,

        pub fn init(form: Form) !Self {
            const vsfs = shaderFiles(fileName);
            const mesh: rl.Mesh = switch (form) {
                .knot => rl.genMeshKnot(1, 1, 16, 64),
                .cube => rl.genMeshCube(1, 1, 1),
            };
            // mesh will be unloaded by model
            const model = try rl.loadModelFromMesh(mesh);

            var prefab = Self{
                .shader = try rl.loadShader(vsfs.vs, vsfs.fs),
                .model = model,
            };
            prefab.model.materials[0].shader = prefab.shader;

            const has_all = hasUniforms(prefab.shader, Self.Uniforms, true);
            dbg.bypassAssert(has_all, false);
            // TODo: why this model uses mateial at index 1 not 0? I this model was exported from blender i think...
            return prefab;
        }

        pub fn deinit(self: Self) void {
            rl.unloadShader(self.shader);
            rl.unloadModel(self.model);
        }

        pub fn repr(self: *const Self, root: rl.Vector3) void {
            rl.gl.rlDisableBackfaceCulling();
            defer rl.gl.rlEnableBackfaceCulling();
            rl.drawModel(self.model, root, 1, rl.Color.blue);
        }

        pub fn setTransform(self: *Self, matrix: rl.Matrix) void {
            const user_mat_loc = getLocation(self.shader, "user_mat");
            rl.setShaderValueMatrix(self.shader, user_mat_loc, matrix);
        }

        pub fn setColor(self: *Self, color: *const rl.Color) void {
            const user_color_loc = getLocation(self.shader, "user_color");
            // rl.setShaderValue(self.shader, user_color_loc, color, .vec4);
            _ = color;
            _ = user_color_loc;
        }
    };
}
