const std = @import("std");
const c = @import("c_imports.zig").c;
const PointerManager = @import("pointer/manager.zig").PointerManager;
const KeyboardManager = @import("keyboard/manager.zig").KeyboardManager;
const InputManager = @import("textinput/manager.zig").InputManager;
const PointerViewInfo = @import("pointer/manager.zig").PointerViewInfo;
const WindowManager = @import("window/manager.zig").WindowManager;
const WindowConfig = @import("window/config.zig").WindowConfig;
const FLWindow = @import("window/window.zig").FLWindow;
const get_aot_data = @import("flutter/aot.zig").get_aot_data;
const create_renderer_config = @import("flutter/renderer_config.zig")
    .create_renderer_config;
const create_flutter_compositor = @import("flutter/compositor.zig")
    .create_flutter_compositor;
const platform_message_callback = @import("./channels/message_callback.zig")
    .platform_message_callback;
const wl_registry_listener = @import("./listeners/registry.zig").wl_registry_listener;
const wl_keyboard_listener = @import("./keyboard/listener.zig").wl_keyboard_listener;
const wl_pointer_listener = @import("./pointer/listener.zig").wl_pointer_listener;
const task = @import("flutter/task_runners.zig");

///Main embedder interface
pub const FLEmbedder = struct {
    gpa: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},
    wl_display: *c.wl_display = undefined,
    registry: *c.wl_registry = undefined,
    seat: ?*c.struct_wl_seat = null,
    windows: WindowManager = WindowManager{},
    pointer: PointerManager = PointerManager{},
    keyboard: KeyboardManager = KeyboardManager{},
    textinput: InputManager = InputManager{},
    runner: task.FLTaskRunner = task.FLTaskRunner{},
    view_surface_map: std.AutoHashMap(*c.struct_wl_surface, i64) = undefined,

    pub fn init(self: *FLEmbedder, path: *[:0]u8) !void {
        self.view_surface_map = std.AutoHashMap(
            *c.struct_wl_surface,
            i64,
        ).init(alloc);
    }

    pub fn run(self: *FLEmbedder) !void {
        _ = c.FlutterEngineRunInitialized(self.engine);
        _ = c.FlutterEngineSendKeyEvent(
            self.engine,
            &c.FlutterKeyEvent{
                .struct_size = @sizeOf(c.FlutterKeyEvent),
            },
            null,
            null,
        );

        while (true) {
            self.runner.run_next_task();
        }
    }

    fn wl_loop(wl: *c.wl_display) void {
        while (true) {
            _ = c.wl_display_dispatch(wl);
        }
    }

    pub fn add_view(self: *FLEmbedder, view: *WindowConfig) !void {
        //TODO: Might need to move this to a windows manager struct
        var window = try self.windows.gpa.allocator().create(FLWindow);
        try window.init(&self.windows, view);

        var event = c.FlutterWindowMetricsEvent{
            .struct_size = @sizeOf(c.FlutterWindowMetricsEvent),
            .width = view.width,
            .height = view.height,
            .pixel_ratio = 1,
            .left = 0,
            .top = 0,
            .physical_view_inset_top = 0,
            .physical_view_inset_right = 0,
            .physical_view_inset_bottom = 0,
            .physical_view_inset_left = 0,
            .display_id = 0,
            .view_id = self.windows.window_count,
        };

        if (self.windows.window_count != 0)
            _ = c.FlutterEngineAddView(
                self.engine,
                &c.FlutterAddViewInfo{
                    .struct_size = @sizeOf(c.FlutterAddViewInfo),
                    .view_id = self.windows.window_count,
                    .user_data = null,
                    .view_metrics = &event,
                    .add_view_callback = add_view_callback,
                },
            );

        const res = c.FlutterEngineSendWindowMetricsEvent(
            self.engine,
            &event,
        );

        if (res != c.kSuccess) {
            std.debug.print("sending window metrics failed\n", .{});
            return error.FailedToSendWindowMetrics;
        }

        try self.view_surface_map.put(
            window.wl_surface,
            self.windows.window_count,
        );

        self.windows.add_view(window) catch {
            std.debug.print("Failed to add view to the window manager \n", .{});
        };
    }

    pub fn remove_view(self: *FLEmbedder, view_id: i64) !void {
        try self.windows.remove_view(view_id);
        const res = c.FlutterEngineRemoveView(
            self.engine,
            &c.FlutterRemoveViewInfo{
                .view_id = view_id,
                .user_data = null,
                .remove_view_callback = &remove_view_callback,
            },
        );

        if (res != c.kSuccess) {
            std.debug.print("Sending window metrics failed\n", .{});
        }
    }
};

