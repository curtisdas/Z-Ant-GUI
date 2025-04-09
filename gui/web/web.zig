const std = @import("std");
const dvui = @import("dvui");
const WebBackend = dvui.backend;
const Backend = dvui.backend;
const entypo = dvui.entypo;
const Color = dvui.Color;
//const zant = @import("zant");

comptime {
    std.debug.assert(@hasDecl(WebBackend, "WebBackend"));
}
usingnamespace WebBackend.wasm;

const WriteError = error{};
const LogWriter = std.io.Writer(void, WriteError, writeLog);

fn writeLog(_: void, msg: []const u8) WriteError!usize {
    WebBackend.wasm.wasm_log_write(msg.ptr, msg.len);
    return msg.len;
}

pub fn logFn(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.enum_literal),
    comptime format: []const u8,
    args: anytype,
) void {
    const level_txt = switch (message_level) {
        .err => "error",
        .warn => "warning",
        .info => "info",
        .debug => "debug",
    };
    const prefix2 = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const msg = level_txt ++ prefix2 ++ format ++ "\n";

    (LogWriter{ .context = {} }).print(msg, args) catch return;
    WebBackend.wasm.wasm_log_flush();
}

pub const std_options: std.Options = .{
    // Overwrite default log handler
    .logFn = logFn,
};

var gpa_instance = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = gpa_instance.allocator();

var win: dvui.Window = undefined;
var backend: WebBackend = undefined;
var touchPoints: [2]?dvui.Point = [_]?dvui.Point{null} ** 2;
var orig_content_scale: f32 = 1.0;

const zant_icon = @embedFile("zant-icon.png");

// Colors
const orange50 = Color{ .r = 255, .g = 252, .b = 234, .a = 255 };
const orange100 = Color{ .r = 255, .g = 245, .b = 197, .a = 255 };
const orange200 = Color{ .r = 255, .g = 235, .b = 133, .a = 255 };
const orange300 = Color{ .r = 255, .g = 219, .b = 70, .a = 255 };
const orange400 = Color{ .r = 255, .g = 200, .b = 27, .a = 255 };
const orange500 = Color{ .r = 255, .g = 166, .b = 2, .a = 255 };
const orange600 = Color{ .r = 226, .g = 125, .b = 0, .a = 255 };
const orange700 = Color{ .r = 187, .g = 86, .b = 2, .a = 255 };
const orange800 = Color{ .r = 152, .g = 66, .b = 8, .a = 255 };
const orange900 = Color{ .r = 124, .g = 54, .b = 11, .a = 255 };
const orange950 = Color{ .r = 72, .g = 26, .b = 0, .a = 255 };
const transparent = Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
const white = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
const black = Color{ .r = 24, .g = 24, .b = 27, .a = 255 };
const border_light = Color{ .r = 212, .g = 212, .b = 216, .a = 255 };
const border_dark = Color{ .r = 39, .g = 39, .b = 42, .a = 255 };
const grey_light = Color{ .r = 249, .g = 249, .b = 249, .a = 255 };
const grey_dark = Color{ .r = 32, .g = 32, .b = 35, .a = 255 };
const button_normal_light = Color{ .r = 240, .g = 240, .b = 240, .a = 255 };
const button_hover_light = Color{ .r = 225, .g = 225, .b = 225, .a = 255 };
const button_pressed_light = Color{ .r = 200, .g = 200, .b = 200, .a = 255 };
const button_normal_dark = Color{ .r = 50, .g = 50, .b = 50, .a = 255 };
const button_hover_dark = Color{ .r = 70, .g = 70, .b = 70, .a = 255 };
const button_pressed_dark = Color{ .r = 100, .g = 100, .b = 100, .a = 255 };
var background_color = white;
var menubar_color = orange50;

// Theme

var first = true;
var darkmode = false;

fn applyTheme() void {
    const theme = dvui.themeGet();
    if (!darkmode) {
        theme.dark = false;
        theme.color_accent = orange500;
        //theme.color_err = red;
        theme.color_text = black;
        theme.color_text_press = black;
        theme.color_fill = white;
        theme.color_fill_window = grey_light;
        theme.color_fill_control = button_normal_light;
        theme.color_fill_hover = button_hover_light;
        theme.color_fill_press = button_pressed_light;
        theme.color_border = border_light;
        background_color = white;
        menubar_color = orange50;
    } else {
        theme.dark = true;
        theme.color_accent = orange500;
        //theme.color_err = red;
        theme.color_text = white;
        theme.color_text_press = white;
        theme.color_fill = black;
        theme.color_fill_window = grey_dark;
        theme.color_fill_control = button_normal_dark;
        theme.color_fill_hover = button_hover_dark;
        theme.color_fill_press = button_pressed_dark;
        theme.color_border = border_dark;
        background_color = black;
        menubar_color = orange950;
    }
}

// Global variables

const Page = enum {
    home,
    select_model,
    generating_code,
    deploy_options,
    generating_library,
};
var page: Page = .home;

var filepath: ?[:0]const u8 = null;
var filename: ?[]const u8 = null;

const ModelOptions = enum(u8) { default, debug_model, mnist_1, mnist_8, sentiment, wake_word, custom };
var model_options: ModelOptions = @enumFromInt(0);
const model_length = @typeInfo(ModelOptions).@"enum".fields.len;

var target_cpu_val: usize = 0;
var target_os_val: usize = 0;

// Helper functions

fn pathToFileName(fp: ?[:0]const u8) []const u8 {
    if (fp == null or fp.?.len == 0) return "";
    const path = fp.?;
    var last_slash: usize = 0;
    for (path, 0..) |c, i| {
        if (c == '/' or c == '\\') {
            last_slash = i + 1;
        }
    }
    var last_dot = path.len;
    for (path[last_slash..], 0..) |c, i| {
        if (c == '.') {
            last_dot = last_slash + i;
        }
    }
    return path[last_slash..last_dot];
}

fn isOnnx(fp: ?[:0]const u8) bool {
    if (fp) |path| {
        const forbidden_chars = [_]u8{ '|', '&', ';', '$', '`', '>', '<' };
        for (forbidden_chars) |c| {
            if (std.mem.indexOfScalar(u8, path, c) != null) {
                return false;
            }
        }
        const extension: []const u8 = ".onnx";
        if (path.len >= extension.len) {
            return std.mem.endsWith(u8, path, extension);
        }
    }
    return false;
}

fn getModelString(value: ModelOptions) []const u8 {
    return switch (value) {
        .default => "",
        .debug_model => "Debug Model",
        .mnist_1 => "MNIST-1",
        .mnist_8 => "MNIST-8",
        .sentiment => "Sentiment",
        .wake_word => "Wake Word",
        .custom => {
            if (filename) |name| {
                return name;
            } else {
                return "Not Selected";
            }
        },
    };
}

fn getModelName(value: ModelOptions) []const u8 {
    return switch (value) {
        .default => "",
        .debug_model => "debug_model",
        .mnist_1 => "mnist-1",
        .mnist_8 => "mnist-8",
        .sentiment => "sentiment_it",
        .wake_word => "wakeWord",
        .custom => {
            if (filename) |name| {
                return name;
            } else {
                return "";
            }
        },
    };
}

// Pages

pub fn pageHome() !void {
    {
        var vbox0 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox0.deinit();

        var heading = try dvui.textLayout(@src(), .{}, .{
            .background = false,
            .margin = .{ .h = 20.0 },
        });
        try heading.addText("Z-Ant Simplifies the Deployment\nand Optimization of Neural Networks\non Microprocessors", .{ .font_style = .title });
        heading.deinit();

        if (try (dvui.button(@src(), "Get Started", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15), .color_fill = .{ .color = orange500 }, .color_fill_hover = .{ .color = orange600 }, .color_fill_press = .{ .color = orange700 }, .color_text = .{ .color = orange950 } }))) {
            page = .select_model;
        }
    }

    var footer = try dvui.textLayout(@src(), .{}, .{
        .background = false,
        .gravity_x = 0.5,
        .gravity_y = 0.8,
    });
    try footer.addText("Z-Ant is an open-source project powered by Zig\nFor help visit our ", .{});
    footer.deinit();
    if (try footer.addTextClick("GitHub", .{ .color_text = .{ .color = orange500 } })) {
        try dvui.openURL("https://github.com/ZantFoundation/Z-Ant");
    }
}

var generating = false;

fn runCodeGen() !void {}

pub fn pageSelectModel() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        page = .home;
    }

    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.3 });
        defer vbox.deinit();

        try dvui.label(@src(), "Select a Model", .{}, .{ .font_style = .title, .margin = .{ .h = 20.0 }, .gravity_x = 0.5 });

        {
            var vbox1 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5 });
            defer vbox1.deinit();

            try dvui.label(@src(), "Built in Models", .{}, .{ .font_style = .heading });

            inline for (@typeInfo(ModelOptions).@"enum".fields[1 .. model_length - 1], 0..) |field, i| {
                const enum_value = @as(ModelOptions, @enumFromInt(field.value));
                const display_name = getModelString(enum_value);
                if (try dvui.radio(@src(), model_options == enum_value, display_name, .{ .id_extra = i })) {
                    model_options = enum_value;
                }
            }

            try dvui.label(@src(), "Custom Model", .{}, .{ .font_style = .heading, .margin = .{ .y = 10.0 } });

            if (try dvui.button(@src(), "Open ONNX File", .{}, .{})) {
                if (filepath) |fp| {
                    filename = null;
                    gpa.free(fp);
                    filepath = null;
                }
                //filepath = try WebBackend.openFilePicker(1, accept: ?[]const u8, multiple: bool)

            }

            const enum_value = @as(ModelOptions, @enumFromInt(model_length - 1));
            const display_name = getModelString(enum_value);
            if (try dvui.radio(@src(), model_options == enum_value, display_name, .{ .id_extra = model_length - 1 })) {
                model_options = enum_value;
            }

            if (try dvui.button(@src(), "Generate Zig Code", .{}, .{ .gravity_x = 0.5, .margin = .{ .y = 20.0 }, .padding = dvui.Rect.all(15), .color_fill = .{ .color = orange500 }, .color_fill_hover = .{ .color = orange600 }, .color_fill_press = .{ .color = orange700 }, .color_text = .{ .color = orange950 } })) {
                if (std.mem.eql(u8, getModelName(model_options), "")) {
                    try dvui.dialog(@src(), .{ .modal = true, .title = "Error", .message = "You must select a model" });
                } else {
                    generating = true;
                    //_ = try std.Thread.spawn(.{}, runCodeGen, .{});
                    page = .generating_code;
                }
            }
        }
    }
}

pub fn pageGeneratingCode() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        if (generating) {
            try dvui.dialog(@src(), .{ .modal = true, .title = "Error", .message = "Wait for code generation to complete" });
        } else {
            page = .select_model;
        }
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox.deinit();
        if (generating) {
            try dvui.label(@src(), "Generating Zig Code ...", .{}, .{
                .font_style = .heading,
                .margin = .{ .h = 2.0 },
            });
        } else {
            try dvui.label(@src(), "Generated Zig Code", .{}, .{
                .font_style = .heading,
                .margin = .{ .h = 2.0 },
            });
        }
        try dvui.label(@src(), "Once completed, the code will be avaialbe for download", .{}, .{ .margin = .{ .h = 10.0 } });

        {
            var hbox = try dvui.box(@src(), .horizontal, .{ .gravity_x = 0.5 });
            defer hbox.deinit();

            if (try dvui.button(@src(), "Save Code", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15) })) {
                //var argv = [_][]const u8{ "open", "generated" };
                //var child = std.process.Child.init(&argv, gpa);
                //try child.spawn();
            }
            if (try dvui.button(@src(), "Continue", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15), .color_fill = .{ .color = orange500 }, .color_fill_hover = .{ .color = orange600 }, .color_fill_press = .{ .color = orange700 }, .color_text = .{ .color = orange950 } })) {
                if (generating) {
                    try dvui.dialog(@src(), .{ .modal = true, .title = "Error", .message = "Wait for code generation to complete" });
                } else {
                    page = .deploy_options;
                }
            }
        }
    }
}

var target_arch_str: ?[:0]const u8 = null;
var target_cpu_str: ?[:0]const u8 = null;

pub fn runLibGen() !void {}

pub fn pageDeployOptions() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        page = .select_model;
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.3 });
        defer vbox.deinit();

        try dvui.label(@src(), "Deploy Options", .{}, .{ .font_style = .title, .margin = .{ .h = 20.0 }, .gravity_x = 0.5 });
        var footer = try dvui.textLayout(@src(), .{}, .{
            .background = false,
            .gravity_x = 0.5,
        });
        try footer.addText("Leave blank to deploy to host machine\nList of ", .{});
        footer.deinit();
        if (try footer.addTextClick("accepted devices", .{ .color_text = .{ .color = orange500 } })) {
            try dvui.openURL("https://github.com/ZantFoundation/Z-Ant");
        }

        {
            var vbox1 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5 });
            defer vbox1.deinit();

            try dvui.label(@src(), "Target Architecture", .{}, .{ .font_style = .heading });
            var target_arch = try dvui.textEntry(@src(), .{}, .{ .gravity_x = 0.5, .margin = .{ .h = 10.0 } });
            target_arch.deinit();
            try dvui.label(@src(), "Specific CPU", .{}, .{ .font_style = .heading });
            var target_cpu = try dvui.textEntry(@src(), .{}, .{ .gravity_x = 0.5, .margin = .{ .h = 20.0 } });
            target_cpu.deinit();

            if (try dvui.button(@src(), "Generate Static Library", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15), .color_fill = .{ .color = orange500 }, .color_fill_hover = .{ .color = orange600 }, .color_fill_press = .{ .color = orange700 }, .color_text = .{ .color = orange950 } })) {
                // test
            }
        }
    }
}

pub fn pageGeneratingLibrary() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        if (generating) {
            try dvui.dialog(@src(), .{ .modal = true, .title = "Error", .message = "Wait for library generation to complete" });
        } else {
            page = .deploy_options;
        }
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox.deinit();
        if (generating) {
            try dvui.label(@src(), "Generating Static Library ...", .{}, .{
                .font_style = .heading,
                .margin = .{ .h = 2.0 },
            });
        } else {
            try dvui.label(@src(), "Generated Static Library", .{}, .{
                .font_style = .heading,
                .margin = .{ .h = 2.0 },
            });
        }
        try dvui.label(@src(), "Once completed, the library will be avaialbe for download", .{}, .{ .margin = .{ .h = 10.0 } });

        {
            var hbox = try dvui.box(@src(), .horizontal, .{ .gravity_x = 0.5 });
            defer hbox.deinit();

            if (try dvui.button(@src(), "Save Library", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15) })) {}

            if (try dvui.button(@src(), "Conclude", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15), .color_fill = .{ .color = orange500 }, .color_fill_hover = .{ .color = orange600 }, .color_fill_press = .{ .color = orange700 }, .color_text = .{ .color = orange950 } })) {
                if (generating) {
                    try dvui.dialog(@src(), .{ .modal = true, .title = "Error", .message = "Wait for library generation to complete" });
                } else {
                    page = .home;
                }
            }
        }
    }
}

export fn app_init(platform_ptr: [*]const u8, platform_len: usize) i32 {
    const platform = platform_ptr[0..platform_len];
    dvui.log.debug("platform: {s}", .{platform});
    const mac = if (std.mem.indexOf(u8, platform, "Mac") != null) true else false;

    backend = WebBackend.init() catch {
        return 1;
    };
    win = dvui.Window.init(@src(), gpa, backend.backend(), .{ .keybinds = if (mac) .mac else .windows }) catch {
        return 2;
    };

    WebBackend.win = &win;

    orig_content_scale = win.content_scale;

    return 0;
}

export fn app_deinit() void {
    win.deinit();
    backend.deinit();
}

// return number of micros to wait (interrupted by events) for next frame
// return -1 to quit
export fn app_update() i32 {
    return update() catch |err| {
        std.log.err("{!}", .{err});
        const msg = std.fmt.allocPrint(gpa, "{!}", .{err}) catch "allocPrint OOM";
        WebBackend.wasm.wasm_panic(msg.ptr, msg.len);
        return -1;
    };
}

fn update() !i32 {
    const nstime = win.beginWait(backend.hasEvent());

    try win.begin(nstime);

    // Instead of the backend saving the events and then calling this, the web
    // backend is directly sending the events to dvui
    //try backend.addAllEvents(&win);

    try dvui_frame();
    //try dvui.label(@src(), "test", .{}, .{ .color_text = .{ .color = dvui.Color.white } });

    //var indices: []const u32 = &[_]u32{ 0, 1, 2, 0, 2, 3 };
    //var vtx: []const dvui.Vertex = &[_]dvui.Vertex{
    //    .{ .pos = .{ .x = 100, .y = 150 }, .uv = .{ 0.0, 0.0 }, .col = .{} },
    //    .{ .pos = .{ .x = 200, .y = 150 }, .uv = .{ 1.0, 0.0 }, .col = .{ .g = 0, .b = 0, .a = 200 } },
    //    .{ .pos = .{ .x = 200, .y = 250 }, .uv = .{ 1.0, 1.0 }, .col = .{ .r = 0, .b = 0, .a = 100 } },
    //    .{ .pos = .{ .x = 100, .y = 250 }, .uv = .{ 0.0, 1.0 }, .col = .{ .r = 0, .g = 0 } },
    //};
    //backend.drawClippedTriangles(null, vtx, indices);

    const end_micros = try win.end(.{});

    backend.setCursor(win.cursorRequested());
    backend.textInputRect(win.textInputRequested());

    const wait_event_micros = win.waitTime(end_micros, null);
    return @intCast(@divTrunc(wait_event_micros, 1000));
}

fn dvui_frame() !void {
    var new_content_scale: ?f32 = null;
    var old_dist: ?f32 = null;
    for (dvui.events()) |*e| {
        if (e.evt == .mouse and (e.evt.mouse.button == .touch0 or e.evt.mouse.button == .touch1)) {
            const idx: usize = if (e.evt.mouse.button == .touch0) 0 else 1;
            switch (e.evt.mouse.action) {
                .press => {
                    touchPoints[idx] = e.evt.mouse.p;
                },
                .release => {
                    touchPoints[idx] = null;
                },
                .motion => {
                    if (touchPoints[0] != null and touchPoints[1] != null) {
                        e.handled = true;
                        var dx: f32 = undefined;
                        var dy: f32 = undefined;

                        if (old_dist == null) {
                            dx = touchPoints[0].?.x - touchPoints[1].?.x;
                            dy = touchPoints[0].?.y - touchPoints[1].?.y;
                            old_dist = @sqrt(dx * dx + dy * dy);
                        }

                        touchPoints[idx] = e.evt.mouse.p;

                        dx = touchPoints[0].?.x - touchPoints[1].?.x;
                        dy = touchPoints[0].?.y - touchPoints[1].?.y;
                        const new_dist: f32 = @sqrt(dx * dx + dy * dy);

                        new_content_scale = @max(0.1, win.content_scale * new_dist / old_dist.?);
                    }
                },
                else => {},
            }
        }
    }

    {
        if (first) {
            applyTheme();
            first = false;
        }
        {
            var m = try dvui.menu(@src(), .horizontal, .{ .background = true, .color_fill = .{ .color = menubar_color }, .expand = .horizontal });
            defer m.deinit();

            const imgsize = try dvui.imageSize("Z-Ant icon", zant_icon);
            try dvui.image(@src(), "Z-Ant icon", zant_icon, .{
                .gravity_y = 0.5,
                .min_size_content = .{ .w = imgsize.w * 0.12, .h = imgsize.h * 0.12 },
                .margin = .{ .x = 20, .y = 10, .h = 10.0, .w = 3.0 },
            });
            try dvui.label(@src(), "Z-Ant", .{}, .{ .gravity_y = 0.5, .font_style = .heading });

            if (try dvui.buttonIcon(@src(), "back", entypo.adjust, .{}, .{ .background = false, .gravity_y = 0.5, .gravity_x = 1.0, .margin = .{ .w = 20.0 }, .color_accent = .{ .color = transparent } })) {
                darkmode = !darkmode;
                applyTheme();
            }
        }

        var scroll = try dvui.scrollArea(@src(), .{}, .{ .expand = .both, .color_fill = .{ .color = background_color } });
        defer scroll.deinit();
        switch (page) {
            .home => try pageHome(),
            .select_model => try pageSelectModel(),
            .generating_code => try pageGeneratingCode(),
            .deploy_options => try pageDeployOptions(),
            .generating_library => try pageGeneratingLibrary(),
        }

        if (new_content_scale) |ns| {
            win.content_scale = ns;
        }
    }
}
