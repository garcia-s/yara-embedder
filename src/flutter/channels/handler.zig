const c = @import("../../utils/c_imports.zig").c;
const YaraEngine = @import("../../engine.zig").YaraEngine;

pub const MessageHandler = *const fn (
    []const u8,
    *YaraEngine,
    ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void;
