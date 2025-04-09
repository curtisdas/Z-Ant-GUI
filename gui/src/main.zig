const std = @import("std");
const dvui = @import("dvui");
const theme = @import("theme.zig");
const AppState = @import("app_state.zig");
const Static = @import("static.zig");
const entypo = dvui.entypo;

const Home = @import("pages/home.zig");
const SelectModel = @import("pages/select_model.zig");
const GeneratingCode = @import("pages/generating_code.zig");
const DeployOptions = @import("pages/deploy_options.zig");
const GeneratingLibrary = @import("pages/generating_library.zig");

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

pub const dvui_app: dvui.App = .{
    .initFn = AppInit,
    .frameFn = AppFrame,
    .deinitFn = AppDeinit,
};

pub const main = dvui.backend.main;
pub const std_options: std.Options = .{
    .logFn = dvui.backend.logFn,
};

pub fn AppInit() void {}

// Run as app is shutting down, need to know if cleanly?
pub fn AppDeinit() void {}

// Run on each frame, return micros to sleep, or something for the app to quit
pub fn AppFrame() void {
    frame() catch return;
}

fn frame() !void {
    var new_content_scale: ?f32 = null;
    var old_dist: ?f32 = null;
    for (dvui.events()) |*e| {
        if (e.evt == .mouse and (e.evt.mouse.button == .touch0 or e.evt.mouse.button == .touch1)) {
            const idx: usize = if (e.evt.mouse.button == .touch0) 0 else 1;
            switch (e.evt.mouse.action) {
                .press => {
                    AppState.touch_points[idx] = e.evt.mouse.p;
                },
                .release => {
                    AppState.touch_points[idx] = null;
                },
                .motion => {
                    if (AppState.touch_points[0] != null and AppState.touch_points[1] != null) {
                        e.handled = true;
                        var dx: f32 = undefined;
                        var dy: f32 = undefined;

                        if (old_dist == null) {
                            dx = AppState.touch_points[0].?.x - AppState.touch_points[1].?.x;
                            dy = AppState.touch_points[0].?.y - AppState.touch_points[1].?.y;
                            old_dist = @sqrt(dx * dx + dy * dy);
                        }

                        AppState.touch_points[idx] = e.evt.mouse.p;

                        dx = AppState.touch_points[0].?.x - AppState.touch_points[1].?.x;
                        dy = AppState.touch_points[0].?.y - AppState.touch_points[1].?.y;
                        const new_dist: f32 = @sqrt(dx * dx + dy * dy);

                        new_content_scale = @max(0.1, dvui.currentWindow().content_scale * new_dist / old_dist.?);
                    }
                },
                else => {},
            }
        }
    }

    if (AppState.first_frame) {
        theme.applyTheme();
        AppState.first_frame = false;
    }

    {
        var m = try dvui.menu(@src(), .horizontal, .{ .background = true, .color_fill = .{ .color = theme.menubar_color }, .expand = .horizontal });
        defer m.deinit();

        const imgsize = try dvui.imageSize("Z-Ant icon", Static.zant_icon);
        _ = try dvui.image(@src(), .{
            .name = "Z-Ant icon",
            .bytes = Static.zant_icon,
        }, .{
            .gravity_y = 0.5,
            .min_size_content = .{ .w = imgsize.w * 0.12, .h = imgsize.h * 0.12 },
            .margin = .{ .x = 20, .y = 10, .h = 10.0, .w = 3.0 },
        });
        try dvui.label(@src(), "Z-Ant", .{}, .{ .gravity_y = 0.5, .font_style = .heading });

        if (try dvui.buttonIcon(@src(), "back", entypo.adjust, .{}, .{ .background = false, .gravity_y = 0.5, .gravity_x = 1.0, .margin = .{ .w = 20.0 }, .color_accent = .{ .color = theme.transparent } })) {
            AppState.darkmode = !AppState.darkmode;
            theme.applyTheme();
        }
    }

    var scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both, .color_fill = .{ .color = theme.background_color } });
    defer scroll.deinit();

    switch (AppState.page) {
        .home => try Home.render(),
        .select_model => try SelectModel.render(gpa),
        .generating_code => try GeneratingCode.render(),
        .deploy_options => try DeployOptions.render(),
        .generating_library => try GeneratingLibrary.render(),
    }

    if (new_content_scale) |ns| {
        dvui.currentWindow().content_scale = ns;
    }
}
