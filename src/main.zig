const std = @import("std");

const YaraEngine = @import("engine.zig").YaraEngine;

pub fn main() anyerror!void {
    const alloc = std.heap.page_allocator;
    const args = try std.process.argsAlloc(alloc);

    if (args.len < 2) {
        return error.InvalidArguments;
    }

    var engine = try YaraEngine.init(&args[1]);

    engine.run() catch |err| {
        std.debug.print(
            "Error running Flutter embedder: {?}\n ",
            .{err},
        );
    };
}
