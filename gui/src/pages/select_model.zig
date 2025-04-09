const std = @import("std");
const dvui = @import("dvui");
const AppState = @import("../app_state.zig");
const Util = @import("../util.zig");
const theme = @import("../theme.zig");
const entypo = dvui.entypo;
const Allocator = std.mem.Allocator;

pub fn render(gpa: Allocator) !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        AppState.page = .home;
    }

    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.3 });
        defer vbox.deinit();

        try dvui.label(@src(), "Select a Model", .{}, .{ .font_style = .title, .margin = .{ .h = 20.0 }, .gravity_x = 0.5 });

        {
            var vbox1 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5 });
            defer vbox1.deinit();

            try dvui.label(@src(), "Built in Models", .{}, .{ .font_style = .heading });

            inline for (@typeInfo(AppState.ModelOptions).@"enum".fields[1 .. AppState.model_length - 1], 0..) |field, i| {
                const enum_value = @as(AppState.ModelOptions, @enumFromInt(field.value));
                const display_name = Util.getModelString(enum_value);
                if (try dvui.radio(@src(), AppState.model_options == enum_value, display_name, .{ .id_extra = i })) {
                    AppState.model_options = enum_value;
                }
            }

            try dvui.label(@src(), "Custom Model", .{}, .{ .font_style = .heading, .margin = .{ .y = 10.0 } });

            if (try dvui.button(@src(), "Open ONNX File", .{}, .{})) {
                if (!@import("builtin").cpu.arch.isWasm()) {
                    _ = try dvui.dialogNativeFileOpen(gpa, .{
                        .path = ".",
                    });
                } else {
                    dvui.dialogWasmFileOpen(0, .{
                        .accept = "text/.onnx",
                    });
                }
            }

            if (!AppState.model_data_ready and AppState.model_options == AppState.ModelOptions.custom) {
                try dvui.spinner(@src(), .{
                    .background = false,
                    .color_accent = .{ .color = theme.orange500 },
                });
            }

            if (@import("builtin").cpu.arch.isWasm()) {
                var wasm_file = dvui.wasmFileUploaded(0);
                if (wasm_file) |*file| {
                    AppState.model_options = AppState.ModelOptions.custom;
                    AppState.model_data_ready = false;
                    const data = try file.readData(gpa);
                    AppState.model_data_ready = true;
                    const sanitized_name = try Util.sanitizeUtf8(gpa, file.name);
                    AppState.model_data = data;
                    AppState.model_name = sanitized_name;
                }
            }

            const enum_value = @as(AppState.ModelOptions, @enumFromInt(AppState.model_length - 1));
            const display_name = Util.getModelString(enum_value);

            if (try dvui.radio(@src(), AppState.model_options == enum_value, display_name, .{ .id_extra = AppState.model_length - 1 })) {
                AppState.model_options = enum_value;
            }

            if (try dvui.button(@src(), "Generate Zig Code", .{}, .{ .gravity_x = 0.5, .margin = .{ .y = 20.0 }, .padding = dvui.Rect.all(15), .color_fill = .{ .color = theme.orange500 }, .color_fill_hover = .{ .color = theme.orange600 }, .color_fill_press = .{ .color = theme.orange700 }, .color_text = .{
                .color = theme.orange950,
            } })) {
                if (std.mem.eql(u8, Util.getModelPath(AppState.model_options), "")) {
                    try dvui.dialog(@src(), .{ .modal = true, .title = "Error", .message = "You must select a model" });
                } else {
                    //std.debug.print("{s}", .{pathToName(getModelPath(model_options))});
                    AppState.page = .generating_code;
                }
            }
        }
    }
}
