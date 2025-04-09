const dvui = @import("dvui");
const theme = @import("../theme.zig");
const entypo = dvui.entypo;
const AppState = @import("../app_state.zig");

pub fn render() !void {
    if (try dvui.buttonIcon(@src(), "back", entypo.chevron_left, .{}, .{ .margin = dvui.Rect.all(15) })) {
        AppState.page = .deploy_options;
    }
    {
        var vbox = try dvui.box(@src(), .vertical, .{ .gravity_x = 0.5, .gravity_y = 0.4 });
        defer vbox.deinit();

        try dvui.label(@src(), "Generating Static Library ...", .{}, .{ .font_style = .heading, .margin = .{ .h = 2.0 } });
        try dvui.label(@src(), "Once completed, the library will be avaialbe in ~/zig-out", .{}, .{ .margin = .{ .h = 10.0 } });

        if (try dvui.button(@src(), "Conclude", .{}, .{ .gravity_x = 0.5, .padding = dvui.Rect.all(15) })) {
            AppState.page = .home;
        }
    }
}
