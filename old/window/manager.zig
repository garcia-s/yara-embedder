const c = @import("../c_imports.zig").c;
const std = @import("std");
const WindowConfig = @import("config.zig").WindowConfig;
const FLWindow = @import("window.zig").FLWindow;

const config_attrib = [_]c.EGLint{
    c.EGL_RENDERABLE_TYPE, c.EGL_OPENGL_ES2_BIT,
    c.EGL_SURFACE_TYPE,    c.EGL_WINDOW_BIT,
    c.EGL_RED_SIZE,        8,
    c.EGL_GREEN_SIZE,      8,
    c.EGL_BLUE_SIZE,       8,
    c.EGL_ALPHA_SIZE,      8,
    // c.EGL_DEPTH_SIZE,      0,
    // c.EGL_STENCIL_SIZE,    8,
    c.EGL_NONE,
};

const ctx_attrib: [*c]c.EGLint = @constCast(&[_]c.EGLint{
    c.EGL_CONTEXT_CLIENT_VERSION, 2,
    c.EGL_NONE,
});

pub const WindowManager = struct {
    mux: std.Thread.RwLock = std.Thread.RwLock{},
    gpa: std.heap.GeneralPurposeAllocator(.{}) =
        std.heap.GeneralPurposeAllocator(.{}){},

    ///Wayland Compositor
    compositor: ?*c.wl_compositor = null,

    layer_shell: ?*c.zwlr_layer_shell_v1 = null,
    ///EGL display
    display: c.EGLDisplay = null,
    config: c.EGLConfig = null,
    context: c.EGLContext = undefined,
    resource_context: c.EGLContext = undefined,

    ///Map used to control the FLWindow instances
    ///To resize, move, close and create windows
    windows: std.AutoHashMap(i64, *FLWindow) = undefined,

    ///The ammount of current windows alive in the current flutter
    window_count: i64 = 0,


    pub fn add_view(self: *WindowManager, window: *FLWindow) !void {
        //TODO: Might need to move this to a windows manager struct
        self.mux.lock();
        defer self.mux.unlock();

        try self.windows.put(self.window_count, window);
        self.window_count += 1;
    }

    pub fn remove_view(self: *WindowManager, view_id: i64) !void {
        self.mux.lock();
        defer self.mux.unlock();

        var window: *FLWindow = self.windows.get(view_id) orelse {
            return error.ViewIdNotFound;
        };

        try window.destroy(self.display);
        _ = self.windows.remove(view_id);
        self.window_count -= 1;
    }

    pub fn get(self: *WindowManager, id: i64) ?*FLWindow {
        self.mux.lock();
        defer self.mux.unlock();
        return self.windows.get(id);
    }
};
