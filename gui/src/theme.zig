const dvui = @import("dvui");
const AppState = @import("app_state.zig");
const Color = dvui.Color;

pub const orange50 = Color{ .r = 255, .g = 252, .b = 234, .a = 255 };
pub const orange100 = Color{ .r = 255, .g = 245, .b = 197, .a = 255 };
pub const orange200 = Color{ .r = 255, .g = 235, .b = 133, .a = 255 };
pub const orange300 = Color{ .r = 255, .g = 219, .b = 70, .a = 255 };
pub const orange400 = Color{ .r = 255, .g = 200, .b = 27, .a = 255 };
pub const orange500 = Color{ .r = 255, .g = 166, .b = 2, .a = 255 };
pub const orange600 = Color{ .r = 226, .g = 125, .b = 0, .a = 255 };
pub const orange700 = Color{ .r = 187, .g = 86, .b = 2, .a = 255 };
pub const orange800 = Color{ .r = 152, .g = 66, .b = 8, .a = 255 };
pub const orange900 = Color{ .r = 124, .g = 54, .b = 11, .a = 255 };
pub const orange950 = Color{ .r = 72, .g = 26, .b = 0, .a = 255 };
pub const transparent = Color{ .r = 0, .g = 0, .b = 0, .a = 0 };
pub const white = Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
pub const black = Color{ .r = 24, .g = 24, .b = 27, .a = 255 };
pub const border_light = Color{ .r = 212, .g = 212, .b = 216, .a = 255 };
pub const border_dark = Color{ .r = 39, .g = 39, .b = 42, .a = 255 };
pub const grey_light = Color{ .r = 249, .g = 249, .b = 249, .a = 255 };
pub const grey_dark = Color{ .r = 32, .g = 32, .b = 35, .a = 255 };
pub const button_normal_light = Color{ .r = 240, .g = 240, .b = 240, .a = 255 };
pub const button_hover_light = Color{ .r = 225, .g = 225, .b = 225, .a = 255 };
pub const button_pressed_light = Color{ .r = 200, .g = 200, .b = 200, .a = 255 };
pub const button_normal_dark = Color{ .r = 50, .g = 50, .b = 50, .a = 255 };
pub const button_hover_dark = Color{ .r = 70, .g = 70, .b = 70, .a = 255 };
pub const button_pressed_dark = Color{ .r = 100, .g = 100, .b = 100, .a = 255 };
pub var background_color = white;
pub var menubar_color = orange50;

pub fn applyTheme() void {
    const theme = dvui.themeGet();
    if (!AppState.darkmode) {
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
