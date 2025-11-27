const c = @import("../c_imports.zig").c;

pub const XKBState = struct {
    fd: i32 = 0,
    size: u32 = 0,
    compose: ?*c.struct_xkb_compose_state = null,
    context: ?*c.struct_xkb_context = null,
    state: ?*c.struct_xkb_state = null,
    keymap: ?*c.struct_xkb_keymap = null,

    //Mod Indexes
    ctrl: u32 = undefined,
    alt: u32 = undefined,
    shift: u32 = undefined,
    supr: u32 = undefined,
    caps: u32 = undefined,
    num: u32 = undefined,
};
