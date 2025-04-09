const std = @import("std");

const ModelOptions = @import("app_state.zig").ModelOptions;
const AppState = @import("app_state.zig");

pub fn getModelString(value: ModelOptions) []const u8 {
    return switch (value) {
        .default => "",
        .debug_model => "Debug Model",
        .mnist_1 => "MNIST-1",
        .mnist_8 => "MNIST-8",
        .sentiment => "Sentiment",
        .wake_word => "Wake Word",
        .custom => AppState.model_name orelse "Custom Model",
    };
}

pub fn getModelPath(value: ModelOptions) []const u8 {
    return switch (value) {
        .default => "",
        .debug_model => "datasets/models/debug_model/debug_model.onnx",
        .mnist_1 => "datasets/models/mnist-1/mnist-1.onnx",
        .mnist_8 => "datasets/models/mnist-8/mnist-8.onnx",
        .sentiment => "datasets/models/Sentiment/sentiment_analysis_it.onnx",
        .wake_word => "datasets/models/wakeWord/wakeWord.onnx",
        .custom => "No path",
    };
}

pub fn sanitizeUtf8(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var valid_utf8 = std.ArrayList(u8).init(allocator);
    defer valid_utf8.deinit();

    var i: usize = 0;
    while (i < input.len) {
        const byte = input[i];
        if (byte < 128) {
            // ASCII character
            try valid_utf8.append(byte);
            i += 1;
        } else {
            // Try to decode the UTF-8 sequence
            var utf8_len: usize = 0;
            if ((byte & 0xE0) == 0xC0) {
                utf8_len = 2;
            } else if ((byte & 0xF0) == 0xE0) {
                utf8_len = 3;
            } else if ((byte & 0xF8) == 0xF0) {
                utf8_len = 4;
            } else {
                // Invalid UTF-8 start byte
                try valid_utf8.append('?');
                i += 1;
                continue;
            }

            // Check if we have enough bytes
            if (i + utf8_len > input.len) {
                try valid_utf8.append('?');
                i += 1;
                continue;
            }

            // Check if the continuation bytes are valid
            var valid = true;
            var j: usize = 1;
            while (j < utf8_len) : (j += 1) {
                if ((input[i + j] & 0xC0) != 0x80) {
                    valid = false;
                    break;
                }
            }

            if (valid) {
                // Copy the entire valid UTF-8 sequence
                try valid_utf8.appendSlice(input[i .. i + utf8_len]);
                i += utf8_len;
            } else {
                try valid_utf8.append('?');
                i += 1;
            }
        }
    }

    return valid_utf8.toOwnedSlice();
}
