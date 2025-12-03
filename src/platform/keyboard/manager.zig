const YaraEngine = @import("../../engine.zig").YaraEngine;
const c = @import("../../utils/c_imports.zig").c;
const wl_keyboard_listener = @import("./listener.zig").wl_keyboard_listener;
const std = @import("std");

pub const KeyboardManager = struct {
    engine: *YaraEngine,

    pub fn init(self: *KeyboardManager) !void {
        const keyboard = c.wl_seat_get_keyboard(self.engine.plaform.seat.?) orelse {
            std.debug.print("Failed to retrieve a pointer", .{});
            return error.ErrorRetrievingPointer;
        };

        _ = c.wl_keyboard_add_listener(
            keyboard,
            &wl_keyboard_listener,
            &self.keyboard,
        );
    }
};
