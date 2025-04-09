const dvui = @import("dvui");
const theme = @import("../theme.zig");
const AppState = @import("../app_state.zig");
const entypo = dvui.entypo;

pub fn render() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        AppState.page = .select_model;
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.3 });
        defer vbox.deinit();

        try dvui.label(@src(), "Deploy Options", .{}, .{ .font_style = .title, .margin = .{ .h = 20.0 }, .gravity_x = 0.5 });

        {
            var vbox1 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5 });
            defer vbox1.deinit();

            const target_cpu = [_][]const u8{ "x86_64", "x86", "arm", "aarch64", "riscv32", "riscv64", "powerpc", "powerpc64", "mips32", "mips64", "wasm32", "wasm64", "sparc", "sparc64" };
            const target_os = [_][]const u8{ "Linux", "Windows", "macOS", "Android", "FreeBSD" };

            try dvui.label(@src(), "Target CPU", .{}, .{ .font_style = .heading, .margin = .{ .h = 5.0 } });
            _ = try dvui.dropdown(@src(), &target_cpu, &AppState.target_cpu_val, .{ .min_size_content = .{ .w = 150 }, .margin = .{ .h = 15.0 } });

            try dvui.label(@src(), "Target OS", .{}, .{ .font_style = .heading, .margin = .{ .h = 5.0 } });
            _ = try dvui.dropdown(@src(), &target_os, &AppState.target_os_val, .{ .min_size_content = .{ .w = 150 }, .margin = .{ .h = 30.0 }, .color_accent = .{ .color = theme.orange500 } });
        }

        if (try dvui.button(@src(), "Generate Static Library", .{}, .{
            .gravity_x = 0.5,
            .padding = dvui.Rect.all(15),
            .color_fill = .{ .color = theme.orange500 },
            .color_fill_hover = .{ .color = theme.orange600 },
            .color_fill_press = .{ .color = theme.orange700 },
            .color_text = .{ .color = theme.orange950 },
        })) {
            AppState.page = .generating_library;
        }
    }
}
