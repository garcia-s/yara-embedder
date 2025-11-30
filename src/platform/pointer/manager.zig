const YaraEngine = @import("../../engine.zig").YaraEngine;
const c = @import("../../utils/c_imports.zig").c;
const std = @import("std");
const wl_pointer_listener = @import("./listener.zig").wl_pointer_listener;

pub const PointerManager = struct {
    engine: *YaraEngine,
    pub fn init(self: *PointerManager) !void {
        const pointer = c.wl_seat_get_pointer(self.seat.?) orelse {
            std.debug.print("Failed to retrieve a pointer", .{});
            return error.ErrorRetrievingPointer;
        };

        _ = c.wl_pointer_add_listener(
            pointer,
            &wl_pointer_listener,
            self,
        );
    }
};
