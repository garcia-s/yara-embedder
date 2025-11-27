const std = @import("std");
const PlatformManager = @import("platform//manager.zig").PlatformManager;
const WindowManager = @import("window/manager.zig").WindowManager;


pub const YaraEngine = struct {

    platform: PlatformManager = PlatformManager{},
    windows: WindowManager = WindowManager{},
    gpa: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},

    pub fn init(self: *YaraEngine, _: *[:0]u8) !void {
        try self.platform.init(self);
        try self.windows.init(self);
    }
    pub fn run(_: *YaraEngine) !void {}
};
