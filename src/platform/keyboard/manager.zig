
const YaraEngine = @import("../../engine.zig").YaraEngine;
const c = @import("../../utils/c_imports.zig").c;
const std = @import("std");

pub const KeyboardManager = struct {
    pub fn init(_: *KeyboardManager) !void {
        const keyboard = c.wl_seat_get_keyboard(self.seat.?) orelse {
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
