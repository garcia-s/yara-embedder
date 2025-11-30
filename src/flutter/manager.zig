const YaraEngine = @import("../engine.zig").YaraEngine;
const c = @import("../../utils/c_imports.zig").c;
const std = @import("std");
const create_renderer_config = @import("flutter/renderer_config.zig")
    .create_renderer_config;
const create_flutter_compositor = @import("flutter/compositor.zig")
    .create_flutter_compositor;
const platform_message_callback = @import("./channels/message_callback.zig")
    .platform_message_callback;
const get_aot_data = @import("./get_aot.zig").get_aot_data;
const task = @import("./task_runners.zig");

pub const FlutterManager = struct {
    engine: *YaraEngine,
    _flutter: *.c.FlutterEngine = undefined,
    _gpa: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},
    _runner: task.FLTaskRunner = task.FLTaskRunner{},

    pub fn init(self: *FlutterManager, path: *[:0]u8) !void {
        const alloc = self._gpa.allocator();

        const assets_path = try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{
            path.*,
            "flutter_assets",
        });

        const icu_path = try std.fmt.allocPrintZ(alloc, "{s}/{s}", .{
            path.*,
            "icudtl.dat",
        });

        var argv = [_][*:0]const u8{
            "--verbose-logging".ptr,
            "--trace-key-events".ptr,
        };

        var args = c.FlutterProjectArgs{
            .struct_size = @sizeOf(c.FlutterProjectArgs),
            .assets_path = @ptrCast(assets_path.ptr),
            .log_message_callback = log_message_callback,
            .icu_data_path = @ptrCast(icu_path.ptr),
            .platform_message_callback = platform_message_callback,
            .channel_update_callback = channel_update_callback,
            .compute_platform_resolved_locale_callback = compute_platform_resolved_locale_callback,
            .command_line_argc = argv.len,
            .command_line_argv = @ptrCast(&argv),
        };

        if (c.FlutterEngineRunsAOTCompiledDartCode()) {
            const aot_path = try std.fmt.allocPrint(alloc, "{s}/{s}", .{
                path.*,
                "lib/libapp.so",
            });

            try get_aot_data(aot_path, &args);
        }

        var config = c.FlutterRendererConfig{
            .type = c.kOpenGL,
            .unnamed_0 = .{ .open_gl = create_renderer_config() },
        };

        try self._runner.init(
            alloc,
            std.Thread.getCurrentId(),
            &self.engine,
        );

        var runner = task.create_fl_runner(&self.runner);
        //
        var runners = c.FlutterCustomTaskRunners{
            .struct_size = @sizeOf(c.FlutterCustomTaskRunners),
            .render_task_runner = @ptrCast(&runner),
            .platform_task_runner = @ptrCast(&runner),
        };
        //
        args.custom_task_runners = @ptrCast(&runners);
        args.compositor = @ptrCast(&create_flutter_compositor(self));

        const res = c.FlutterEngineInitialize(
            1,
            &config,
            &args,
            self,
            &self.engine,
        );

        //I need the context and surfaces before the thing
        if (res != c.kSuccess) {
            return error.FailedToRunFlutterEngine;
        }
    }
};

//Empty callback called after a flutter view is created, maybe for other channels?
//Like for channels other than the normal channels
pub fn add_view_callback(
    _: [*c]const c.FlutterAddViewResult,
) callconv(.C) void {}

pub fn remove_view_callback(
    _: [*c]const c.FlutterRemoveViewResult,
) callconv(.C) void {}
//I have no idea what this is for
//
fn channel_update_callback(
    _: [*c]const c.FlutterChannelUpdate,
    _: ?*anyopaque,
) callconv(.C) void {}

// I don't remember how this work, i'm probably going to need this function at some point
pub fn compute_platform_resolved_locale_callback(
    locales: [*c][*c]const c.FlutterLocale,
    _: usize,
) callconv(.C) [*c]const c.FlutterLocale {
    std.debug.print("Running the locales thingy\n", .{});
    return locales[0];
}

pub fn log_message_callback(
    tag: [*c]const u8,
    message: [*c]const u8,
    _: ?*anyopaque,
) callconv(.C) void {
    std.debug.print("{s}: {s}\n", .{ tag, message });
}
