const Build = @import("std").Build;

pub fn build(b: *Build) !void {
    _ = b.addModule("mount", .{ .root_source_file = b.path("mount.zig") });
}
