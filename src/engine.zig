const std = @import("std");
const PlatformManager = @import("platform//manager.zig").PlatformManager;
const WindowManager = @import("window/manager.zig").WindowManager;

pub const YaraEngine = struct {
    platform: PlatformManager,
    windows: WindowManager,
    gpa: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},

    pub fn init(_: *[:0]u8) !YaraEngine {
        var engine = YaraEngine{
            .platform = undefined,
            .windows = undefined,
        };

        engine.platform = PlatformManager{ .engine = &engine };
        engine.windows = WindowManager{ .engine = &engine };

        try engine.platform.init();
        try engine.windows.init();
        return engine;
    }
    pub fn run(_: *YaraEngine) !void {}
};
