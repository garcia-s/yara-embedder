const std = @import("std");
const c = @import("../utils/c_imports.zig").c;

const YaraEngine = @import("../engine.zig").YaraEngine;
const wl_registry_listener = @import("./wl_registry_listener.zig").wl_registry_listener;
const KeyboardManager = @import("./keyboard/manager.zig").KeyboardManager;
const PointerManager = @import("./pointer/manager.zig").PointerManager;

pub const PlatformManager = struct {
    engine: *YaraEngine,
    display: *c.wl_display = undefined,
    registry: *c.wl_registry = undefined,
    seat: ?*c.struct_wl_seat = null,

    keyboard: KeyboardManager = KeyboardManager{},
    pointer: PointerManager = PointerManager{},

    pub fn init(self: *PlatformManager) !void {
        self.display = c.wl_display_connect(null) orelse {
            return error.WaylandConnectionFailed;
        };

        self.registry = c.wl_display_get_registry(self.display) orelse {
            return error.WaylandGetRegistryFailed;
        };

        std.debug.print("Succesfully got the registry\n", .{});
        const reg_result = c.wl_registry_add_listener(
            self.registry,
            &wl_registry_listener,
            self,
        );

        if (reg_result < 0)
            return error.WaylandRegistryListenerFailed;

        std.debug.print("Registered WL Registry Listener\n", .{});
        _ = c.wl_display_roundtrip(self.display);

        if (self.seat == null) return error.WaylandSeatUnintialized;
        std.debug.print("Seat was bounded correctly\n", .{});

        //try self.windows.init(self.wl_display);
        _ = try std.Thread.spawn(.{}, wl_loop, .{self.display});
        std.debug.print("Initialized the Wayland dispatch loop\n", .{});

        try self.keyboard.init();
        try self.pointer.init();
    }

    fn wl_loop(wl: ?*c.wl_display) void {
        while (true) {
            _ = c.wl_display_dispatch(wl.?);
        }
    }
};
