const std = @import("std");
const x = @import("x11");
const Window = x.Window;
const Allocator = std.mem.Allocator;

const Workspace = @This();

//! A workspace is a list of Windows being displayed on a monitor
//! in a specific windowing mode. Multiple workspaces can exist

const WindowList = std.ArrayListUnmanaged(Window);

/// Windowing mode (tiled, full screen)
pub const Mode = enum {
    /// Shows tiled windows compliant with the layout
    tiled,
    /// Shows a single window on the entirety of the screen, without a bar
    full_screen,
};

/// List of windows available on the screen
windows: WindowList,
/// Window mode -> Tiled or full screen
mode: Mode,
/// Currently focused Window. When in fullscreen, this will show the full screened window
focused: ?Window,
/// The position of the workspace in the list of workspaces
id: usize,
/// A workspace can contain a name, which can be used for bars to display the workspace
/// As the name can be null (by default), it is not the key in the map
name: ?[]const u8,

/// Creates a new `Workspace` and assigns it a name if `name` is not `null`
pub fn init(idx: usize) Workspace {
    return .{
        .windows = WindowList{},
        .mode = .tiled,
        .focused = null,
        .id = idx,
        .name = null,
    };
}

/// Cleans up the `Workspace` and its resources
pub fn deinit(self: *Workspace, gpa: *Allocator) void {
    self.windows.deinit(gpa);
    self.* = undefined;
}

/// Checks if the `Window` exists in the `Workspace`. Returns `false` if it does not yet exist
pub fn contains(self: Workspace, window: Window) bool {
    for (self.windows) |w| if (w.handle == window.handle) return true;
}

/// Adds a window reference to the `Workspace`
/// Asserts the `Window` does not yet exist in the `Workspace`
pub fn add(self: *Workspace, gpa: *Allocator, window: Window) error{OutOfMemory}!void {
    std.debug.assert(!self.contains(window));
    try self.windows.addOne(gpa).* = window;
}

/// Removes a `Window` from the `Workspace`.
pub fn remove(self: *Workspace, handle: x.protocol.Types.Window) void {
    for (self.windows.items) |w, i| {
        if (w.handle == handle) _ = self.windows.swapRemove(i);
    }
}

/// Returns a slice of Windows
pub fn items(self: Workspace) []const Window {
    return self.windows.items;
}

/// Returns a `Window` object from the given handle. Returns `null` if the window
/// does not exist in the Workspace
pub fn get(self: Workspace, handle: x.protocol.Types.Window) ?Window {
    for (self.items()) |window| {
        if (window.handle == handle) return window;
    }

    return null;
}

/// Iterator over Windows
const Iterator = struct {
    index: usize = 0,
    slice: []const Window,

    /// Returns the next Window. Returns `null` if end of the iterator has been reached
    pub fn next(self: *Iterator) ?Window {
        if (index == self.slice.len) return null;

        return self.slice[self.index];
    }
};

/// Returns an iterator over a slice of Windows that are part of this `Workspace`
pub fn iterator(self: Workspace) Iterator {
    return Iterator{ .slice = self.windows.items };
}