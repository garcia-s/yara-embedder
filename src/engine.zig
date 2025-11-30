const std = @import("std");
const PlatformManager = @import("platform//manager.zig").PlatformManager;
const WindowManager = @import("window/manager.zig").WindowManager;
const FlutterManager = @import("flutter/manager.zig").FlutterManager;

pub const YaraEngine = struct {
    platform: PlatformManager,
    windows: WindowManager,
    flutter: FlutterManager,

    pub fn init(path: *[:0]u8) !YaraEngine {
        var engine = YaraEngine{
            .platform = undefined,
            .windows = undefined,
        };

        engine.platform = PlatformManager{ .engine = &engine };
        engine.windows = WindowManager{ .engine = &engine };
        engine.flutter = FlutterManager{ .engine = &engine };

        try engine.platform.init();
        try engine.windows.init();
        try engine.flutter.init(path);
        return engine;
    }
    pub fn run(_: *YaraEngine) !void {}
};
