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
const vi2 = math.iv2;
const vf2 = math.fv2;

const AppMemory = @import("core.zig").AppMamory;
pub fn program(aloc: *const AppMemory) void {
    runSimInMemory(aloc) catch {
        std.debug.print("error cleaning\n", .{});
    };
}

const RLWindow = struct {
    corner: vf2,
    size: vf2,
};

const RenderMedium = union(enum) {
    window: *RLWindow,
    target: rl.RenderTexture,

    pub fn begin(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.beginDrawing(),
            RenderMedium.target => |rtxt| rl.beginTextureMode(rtxt),
        }
    }

    pub fn end(self: RenderMedium) void {
        switch (self) {
            RenderMedium.window => rl.endDrawing(),
            RenderMedium.target => rl.endTextureMode(),
        }
    }
};

fn render_model() !void {
    const img_size = 1344;
    var on_medium: RenderMedium = RenderMedium{
        .target = rl.RenderTexture2D.init(img_size, img_size),
    };
    defer on_medium.target.unload();
    // const textTo: [1024]u8 = undefined;
    // const textTo1: []u8 = textTo[0..];

    var model = rl.loadModel("assets/hand.glb");
    defer model.unload();

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

    var fmt_memory: [1024]u8 = undefined;
    const fmt_buf = fmt_memory[0..];
    const fname_fmt = "fs/render_viwe_{d}.png";
    {
        on_medium.begin();
        defer on_medium.end();

        // # region update
        rl.updateCamera(&camera, rl.CameraMode.camera_custom);
        // # region render
        rl.beginMode3D(camera);
        defer rl.endMode3D();

        rl.clearBackground(rl.Color.white);

        rl.drawModel(model, center, 1, rl.Color.gray);

        var img = rl.loadImageFromTexture(on_medium.target.texture);
        defer img.unload();
        img.flipVertical();

        const i = 0;
        const fname = try std.fmt.bufPrintZ(fmt_buf, fname_fmt, .{i});
        _ = img.exportToFile(fname);
    }
}

fn runSimInMemory(mem: *const AppMemory) !void {
    const screenWidth = 1600;
    const screenHeight = 900;
    var window = RLWindow{
        .corner = vf2{ screenWidth, 0 },
        .size = vf2{ screenWidth, screenWidth },
    };

    const title: [:0]const u8 = "+++ Runing simulation in a window +++";
    rl.initWindow(screenWidth, screenHeight, title.ptr);
    defer rl.closeWindow();
    try _simulation(mem, &window);
}

fn _simulation(aloc: *const AppMemory, win: *RLWindow) !void {
    const arena = aloc.arena;
    _ = arena;
    // const text_alloc = aloc.gpa;
    var on_medium: RenderMedium = RenderMedium{ .window = win };

    try render_model();

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

    const dot_number: u32 = 256;

    var simple_benchmark = elems.SurfaceInfo(dot_number){ .tiles = undefined };
    simple_benchmark.benchGrid(win.size);

    var imgB = ImageBox{};
    imgB.imageLoadTry();

    var fmt_memory: [1024]u8 = undefined;
    const fmt_buf = fmt_memory[0..];
    // TODO: będę tu testował rendering obrazka
    // na przykład tworząc prosty system cząstekowy
    // gdzie particle sobie oscylują w różnych miejscach
    // to mógłby byś w pewnym sensie pewien benchmark wydajności
    while (exit.toContinue()) {
        // exit_key.check_input();
        const delta_ms = try tmln.tickMs();
        const fps = 1000 / delta_ms;
        life_time_ms += @floatCast(delta_ms);

        const mouse_pose = input.sample_mouse();

        for (&skill_keys) |*skill_key| skill_key.collectiInput();
        exit.collectInput();
        const pointer_pos = rl.Vector3.init(mouse_pose[0], mouse_pose[1], 0);

        // for(& skill_keys) | *|
        exit.update(delta_ms);

        const info_tmpl: []const u8 = "Congrats! You created your first window!\n Frame time {d:.3}ms\n fps {d}\n";
        const info_text = try std.fmt.bufPrintZ(fmt_buf, info_tmpl, .{ delta_ms, fps });
        // defer text_alloc.free(info);

        on_medium.begin();
        defer on_medium.end();

        rl.clearBackground(THEME[0]);
        exit.draw();
        simple_benchmark.draw();

        rl.drawCircle3D(pointer_pos, 10, rl.Vector3.init(0, 0, 0), 0, rl.Color.dark_blue);

        repr.frame(mouse_pose, false);
        rl.drawText(info_text, 50, 50, 20, THEME[1]);
        imgB.repr();
    }
}
