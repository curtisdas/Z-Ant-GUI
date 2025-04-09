const dvui = @import("dvui");

pub const Page = enum {
    home,
    select_model,
    generating_code,
    deploy_options,
    generating_library,
};

pub const ModelOptions = enum(u8) {
    default,
    debug_model,
    mnist_1,
    mnist_8,
    sentiment,
    wake_word,
    custom,
};

pub var page: Page = .home;
pub var model_options: ModelOptions = .default;
pub const model_length = @typeInfo(ModelOptions).@"enum".fields.len;
pub var org_content_scale: f32 = 1;
pub var touch_points: [2]?dvui.Point = undefined;
pub var first_frame: bool = true;
pub var darkmode = false;
pub var target_cpu_val: usize = 0;
pub var target_os_val: usize = 0;

// Wasm specific variables
pub var model_name: ?[]const u8 = null;
pub var model_data: ?[]const u8 = null;
pub var model_data_ready: bool = false;
