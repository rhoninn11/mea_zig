const std = @import("std");
const rl = @import("raylib");
const math = @import("mods/core/math.zig");
const repr = @import("mods/core/repr.zig");
const elems = @import("mods/elements.zig");

const Allocator = std.mem.Allocator;
const Timeline = @import("mods/time.zig").Timeline;

const Vec2i = @import("mods/core/math.zig").Vec2i;
const THEME = @import("mods/core/repr.zig").Theme;

fn log_slice_info(slice: []f32) void {
    std.debug.print("---\n", .{});
    for (slice) |num_val| {
        std.debug.print(" num value is: {d:.2}\n", .{num_val});
    }
}

const spt = @import("spatial.zig");

const phys = @import("mods/phys.zig");
const Iner = phys.Inertia;
const PhysInprint = phys.PhysInprint;

const ImageBox = @import("ImageBox.zig");

const input = @import("mods/input.zig");
const vi2 = math.vi2;
const vf2 = math.vf2;

const AppMemory = @import("core.zig").AppMamory;
pub fn program(aloc: *const AppMemory) void {
    runSimInMemory(aloc) catch {
        std.debug.print("error cleaning\n", .{});
    };
}

// TODO: that would be cool if i could render the same content on different mediums
fn render_model() void {
    const img_size = 1344;
    var rt2d = rl.RenderTexture2D.init(img_size, img_size);
    defer rt2d.unload();
    // const textTo: [1024]u8 = undefined;
    // const textTo1: []u8 = textTo[0..];

    var model = rl.loadModel("fs/sample/StainedGlassLamp.gltf");
    defer model.unload();

    std.debug.print("+++ model has {d} meshes and {d} materials", .{ model.meshCount, model.materialCount });

    const center = rl.Vector3.init(0, 0, 0);
    var camera = rl.Camera{
        .up = rl.Vector3.init(0, 1, 0),
        .position = center,
        .target = center,
        .fovy = 60,
        .projection = rl.CameraProjection.camera_perspective,
    };
    camera.target = rl.Vector3.init(0, 1, 0);
    // view = camera.getMatrix();
    const camera_pos = rl.Vector3.init(2, 0.5, 0);
    camera.position = camera_pos;

    rt2d.begin();
    defer rt2d.end();

    // # region update
    rl.updateCamera(&camera, rl.CameraMode.camera_custom);
    // # region render
    rl.beginMode3D(camera);
    defer rl.endMode3D();

    rl.clearBackground(rl.Color.white);

    rl.drawModel(model, center, 3, rl.Color.gray);

    var img = rl.loadImageFromTexture(rt2d.texture);
    defer img.unload();
    img.flipVertical();

    const file_name = "fs/render_viwe_{d}.png";
    // std.fmt.bufPrintZ(textTo1, "fs/render_viwe_{d}.png", .{0});
    _ = img.exportToFile(file_name);
}

const RLWindow = struct {
    corner: vf2,
    size: vf2,
};

const RenderMedium = union(enum) {
    window: RLWindow,
    target: rl.RenderTexture,

    pub fn begin(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.beginDrawing(),
            RenderMedium.target => |rtxt| rl.beginTextureMode(rtxt),
        }
    }

    pub fn end(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.beginDrawing(),
            RenderMedium.target => |rtxt| rl.beginTextureMode(rtxt),
        }
    }
};

fn runSimInMemory(mem: *const AppMemory) !void {
    const screenWidth = 1600;
    const screenHeight = 900;
    var window = RLWindow{
        .corner = vf2{ screenWidth, 0 },
        .size = vf2{ screenWidth, screenWidth },
    };

    const title: [:0]const u8 = "+++ Runing simulation in window +++";
    rl.initWindow(screenWidth, screenHeight, title.ptr);
    defer rl.closeWindow();
    try _simulation(mem, &window);
}

fn _simulation(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    _ = arena;
    // const text_alloc = aloc.gpa;

    // render_model();

    var tmln = try Timeline.basic();
    var life_time_ms: f64 = 0;

    // kb input
    const n = 5;
    _ = n;
    const action_key = "qwert";
    var skill_keys = input.obtain_keys(action_key.len, action_key);

    // elements
    var exit = elems.Exiter.spawn(win.corner, rl.KeyboardKey.key_escape);
    exit.selfReference();

    const dot_number: u32 = 1024;

    var simple_benchmark = elems.SurfaceInfo(dot_number){ .tiles = undefined };
    simple_benchmark.benchGrid(win.size);

    var imgB = ImageBox{};
    imgB.imageLoadTry();

    var text_memory: [1024]u8 = undefined;
    const text_buffer = text_memory[0..];
    // TODO: będę tu testował rendering obrazka
    // na przykład tworząc prosty system cząstekowy
    // gdzie particle sobie oscylują w różnych miejscach
    // to mógłby byś w pewnym sensie pewien benchmark wydajności
    while (exit.toContinue()) {
        // exit_key.check_input();
        const delta_ms = try tmln.tickMs();
        life_time_ms += @floatCast(delta_ms);

        const mouse_pose = input.sample_mouse();

        for (&skill_keys) |*skill_key| skill_key.check_input(delta_ms);
        exit.update(delta_ms);

        const info_tmpl: []const u8 = "Congrats! You created your first window!\n Frame time {d:.3}ms\n fps {d}\n";
        // const info = try std.fmt.allocPrintZ(text_alloc, info_template, .{});
        const info_text = try std.fmt.bufPrintZ(text_buffer, info_tmpl, .{ delta_ms, 1000 / delta_ms });
        // defer text_alloc.free(info);

        rl.beginDrawing();

        rl.clearBackground(THEME[0]);
        exit.draw();
        simple_benchmark.draw();

        const pointer_pos = rl.Vector3.init(mouse_pose[0], mouse_pose[1], 0);
        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);

        repr.frame(mouse_pose, false);
        rl.drawText(info_text, 50, 50, 20, THEME[1]);
        imgB.repr();

        rl.endDrawing();
    }
}
