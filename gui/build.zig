const std = @import("std");
pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    // Web build step
    const web_step = b.step("web", "Build the web application");
    // Native build step
    const native_step = b.step("native", "Build the native application");

    // === WASM/WEB BUILD ===
    {
        const target = b.standardTargetOptions(.{
            .default_target = .{ .cpu_arch = .wasm32, .os_tag = .freestanding },
        });
        const dvui_dep = b.dependency("dvui", .{
            .target = target,
            .optimize = optimize,
            .backend = .web,
        });
        const exe = b.addExecutable(.{
            .name = "web",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });

        // Add the CodeGen module

        // Add WASM-specific flags to disable problematic features
        exe.root_module.addCMacro("INCLUDE_CUSTOM_LIBC_FUNCS", "1");
        exe.root_module.addCMacro("STBI_NO_STDLIB", "1");
        exe.root_module.addCMacro("STBIW_NO_STDLIB", "1");
        exe.root_module.addImport("dvui", dvui_dep.module("dvui_web"));
        exe.entry = .disabled;
        exe.rdynamic = true;

        // Install WASM binary
        const install_wasm = b.addInstallArtifact(exe, .{
            .dest_dir = .{ .override = .{ .custom = "bin/web" } },
        });
        web_step.dependOn(&install_wasm.step);

        // Install all files from src/static
        const install_web_files = b.addInstallDirectory(.{
            .source_dir = b.path("src/static"),
            .install_dir = .{ .custom = "bin/web" },
            .install_subdir = "",
        });
        web_step.dependOn(&install_web_files.step);

        // Copy DVUI's web.js file which is needed for the WASM interface
        const web_js = dvui_dep.path("src/backends/web.js");
        const copy_web_js = b.addInstallFileWithDir(web_js, .{ .custom = "bin/web" }, "web.js");
        web_step.dependOn(&copy_web_js.step);
    }

    // === NATIVE BUILD ===
    {
        const native_target = b.resolveTargetQuery(.{});
        const native_dvui_dep = b.dependency("dvui", .{
            .target = native_target,
            .optimize = optimize,
            .backend = .sdl,
        });
        const native_exe = b.addExecutable(.{
            .name = "native",
            .root_source_file = b.path("src/main.zig"),
            .target = native_target,
            .optimize = optimize,
        });

        native_exe.root_module.addImport("dvui", native_dvui_dep.module("dvui_sdl"));
        const install_native = b.addInstallArtifact(native_exe, .{
            .dest_dir = .{ .override = .{ .custom = "bin/native" } },
        });
        native_step.dependOn(&install_native.step);

        // Add run step for native version
        const run_cmd = b.addRunArtifact(native_exe);
        const run_step = b.step("run", "Run the native application");
        run_step.dependOn(&run_cmd.step);
    }

    // Rest of your build file remains unchanged
    const exe_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
    });
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(exe_tests).step);

    // Make default step build both web and native
    b.getInstallStep().dependOn(web_step);
    b.getInstallStep().dependOn(native_step);
}
