const std = @import("std");
const c = @import("../../utils/c_imports.zig").c;
const MessageHandler = @import("../channels/handler.zig").MessageHandler;
const YaraEngine = @import("../../engine.zig").YaraEngine;
const TextInputClient = @import("messages.zig").TextInputClient;
const EditingValue = @import("messages.zig").EditingValue;


const TextInputHandler = *const fn (
    *const ?std.json.Value,
    *YaraEngine,
    ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void;

const textinput_channel = std.StaticStringMap(TextInputHandler).initComptime(.{
    .{ "TextInput.setEditingState", set_editing_state },
    .{ "TextInput.setClient", set_client },
    // TextInput.setEditableSizeAndTransform
    // TextInput.setMarkedTextRect
    // TextInput.setStyle
    // TextInput.setEditingState
    // TextInput.show
    // TextInput.requestAutofill
    // TextInput.setCaretRect
});

pub fn textinput_channel_handler(
    message: []const u8,
    engine: *YaraEngine,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    var gp = std.heap.GeneralPurposeAllocator(.{}){};

    // std.debug.print("Message: {s}", .{message});
    const p = std.json.parseFromSlice(
        std.json.Value,
        gp.allocator(),
        message,
        .{ .ignore_unknown_fields = true },
    ) catch return;

    defer p.deinit();
    const m = p.value.object.get("method") orelse {
        return send_empty_response(engine, handle);
    };

    const args = p.value.object.get("args");

    const method = textinput_channel.get(m.string) orelse {
        const data = "";
        _ = c.FlutterEngineSendPlatformMessageResponse(
            engine.engine,
            handle,
            data.ptr,
            data.len,
        );
        return;
    };
    //
    try method(&args, engine, handle);
}

pub fn set_editing_state(
    args: *const ?std.json.Value,
    engine: *YaraEngine,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    const a = args.* orelse {
        return send_empty_response(engine, handle);
    };

    const p = std.json.parseFromValue(
        EditingValue,
        engine.keyboard.input.gp.allocator(),
        a,
        .{ .ignore_unknown_fields = true },
    ) catch return send_empty_response(
        engine,
        handle,
    );

    engine.keyboard.input.editing_value = p.value;
    return send_empty_response(engine, handle);
}

pub fn set_client(
    args: *const ?std.json.Value,
    engine: *YaraEngine,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) anyerror!void {
    const a = args.* orelse {
        return send_empty_response(engine, handle);
    };

    engine.keyboard.input.current_id = a.array.items[0].integer;

    const p = std.json.parseFromValue(
        TextInputClient,
        engine.keyboard.input.gp.allocator(),
        a.array.items[1],
        .{ .ignore_unknown_fields = true },
    ) catch |e| {
        std.debug.print("Error parsing, {?}\n", .{e});
        return send_empty_response(
            engine,
            handle,
        );
    };

    engine.keyboard.input.text_client = p.value;

    //TODO: Don't know if this is the way to respond
    return send_empty_response(
        engine,
        handle,
    );
}

pub fn send_empty_response(
    engine: *YaraEngine,
    handle: ?*const c.FlutterPlatformMessageResponseHandle,
) void {
    const data = "[0]";
    _ = c.FlutterEngineSendPlatformMessageResponse(
        engine.engine,
        handle,
        data.ptr,
        data.len,
    );
}
