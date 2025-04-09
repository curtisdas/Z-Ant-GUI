const dvui = @import("dvui");
const theme = @import("../theme.zig");
const AppState = @import("../app_state.zig");

pub fn render() !void {
    {
        var vbox0 = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox0.deinit();

        var heading = try dvui.textLayout(@src(), .{}, .{
            .background = false,
            .margin = .{ .h = 20.0 },
        });
        try heading.addText("Z-Ant Simplifies the Deployment\nand Optimization of Neural Networks\non Microprocessors", .{ .font_style = .title });
        heading.deinit();

        if (try (dvui.button(@src(), "Get Started", .{}, .{
            .gravity_x = 0.5,
            .padding = dvui.Rect.all(15),
            .color_fill = .{ .color = theme.orange500 },
            .color_fill_hover = .{ .color = theme.orange600 },
            .color_fill_press = .{ .color = theme.orange700 },
            .color_text = .{ .color = theme.orange950 },
        }))) {
            AppState.page = .select_model;
        }
    }

    var footer = try dvui.textLayout(@src(), .{}, .{
        .background = false,
        .gravity_x = 0.5,
        .gravity_y = 0.8,
    });
    try footer.addText("Z-Ant is an open-source project powered by Zig\nFor help visit our ", .{});
    footer.deinit();
    if (try footer.addTextClick("GitHub", .{
        .color_text = .{ .color = theme.orange500 },
    })) {
        try dvui.openURL("https://github.com/ZantFoundation/Z-Ant");
    }
}
