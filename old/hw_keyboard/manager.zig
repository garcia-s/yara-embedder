const c = @import("../c_imports.zig").c;
const std = @import("std");
const EditingValue = @import("../textinput/messages.zig").EditingValue;
const XKBState = @import("../keyboard/xkb.zig").XKBState;
const keymap = @import("../keyboard/keymap.zig");

const message =
    \\  {
    \\      "keymap": "linux",
    \\      "toolkit": "gtk",
    \\      "type": "keydown"
    \\  }
;

pub const HWKeyboardManager = struct {
    xkb: *XKBState = undefined,
    event: c.FlutterKeyEvent = c.FlutterKeyEvent{
        .struct_size = @sizeOf(c.FlutterKeyEvent),
        .device_type = c.kFlutterKeyEventDeviceTypeKeyboard,
        // timestamp: f64 = @import("std").mem.zeroes(f64),
        // type: FlutterKeyEventType = @import("std").mem.zeroes(FlutterKeyEventType),
        // physical: u64 = @import("std").mem.zeroes(u64),
        // logical: u64 = @import("std").mem.zeroes(u64),
        // character: [*c]const u8 = @import("std").mem.zeroes([*c]const u8),
        // synthesized: bool = @import("std").mem.zeroes(bool),
        // device_type: FlutterKeyEventDeviceType = @import("std").mem.zeroes(FlutterKeyEventDeviceType),
    },

    pub fn init(self: *HWKeyboardManager, xkb: *XKBState) void {
        self.xkb = xkb;
    }

    pub fn handle_input(
        self: *HWKeyboardManager,
        key: u32,
        state: u32,
        engine: *c.FlutterEngine,
    ) void {
        self.event.type = switch (state) {
            0 => c.kFlutterKeyEventTypeUp,
            1 => c.kFlutterKeyEventTypeDown,
            2 => c.kFlutterKeyEventTypeRepeat,
            else => 0,
        };
        self.event.synthesized = true;
        self.event.timestamp = @as(f64, @floatFromInt(c.FlutterEngineGetCurrentTime())) / 1000.0;
        // self.event.physical = 0x0007002b;
        self.event.physical = @intCast(keymap.udev_to_physical(key));
        // self.event.logical = 0x00100000009;
        self.event.logical = keymap.xkb_to_logical(
            c.xkb_state_key_get_one_sym(
                self.xkb.state,
                key + 8,
            ),
        );

        std.debug.print(
            "Logical: {d} \nPhysical: {d} \nkey: {d}\n",
            .{ self.event.logical, self.event.physical, key },
        );

        _ = c.FlutterEngineSendKeyEvent(
            engine.*,
            &self.event,
            &key_event_callback,
            null,
        );

        _ = c.FlutterEngineSendPlatformMessage(
            engine.*,
            &c.FlutterPlatformMessage{
                .struct_size = @sizeOf(c.FlutterPlatformMessage),
                .channel = "flutter/keyevent",
                .message = message,
                .message_size = message.len,
            },
        );
    }
};

fn key_event_callback(correct: bool, _: ?*anyopaque) callconv(.C) void {
    if (!correct) std.debug.print("Key data was not sent correctly\n", .{});
    return;
}
