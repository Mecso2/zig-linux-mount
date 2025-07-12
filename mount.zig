const std = @import("std");

fn fsopen(fsname: [*:0]const u8, cloexec: bool) !i32 {
    const rc = std.os.linux.syscall2(.fsopen, @intFromPtr(fsname), @intFromBool(cloexec));
    const signed: isize = @bitCast(rc);
    const code: std.posix.E = @enumFromInt(if (signed > -4096 and signed < 0) -signed else 0);
    return switch (code) {
        .SUCCESS => @intCast(signed),
        .FAULT => unreachable,
        .INVAL => unreachable,
        .MFILE, .NFILE => error.ProcessFdQuotaExceeded,
        .NODEV => error.FsNameNotFound,
        .NOMEM => error.SystemResources,
        .PERM => error.PermissionDenied,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

const FsconfigCommand = enum(u32) {
    SetFlag = 0, // Set parameter, supplying no value
    SetString = 1, // Set parameter, supplying a string value
    SetBinary = 2, // Set parameter, supplying a binary blob value
    SetPath = 3, // Set parameter, supplying an object by path
    SetPathEmpty = 4, // Set parameter, supplying an object by (empty) path
    SetFd = 5, // Set parameter, supplying an object by fd
    CmdCreate = 6, // Create new or reuse existing superblock
    CmdReconfigure = 7, // Invoke superblock reconfiguration
    CmdCreateExcl = 8, // Create new superblock, fail if reusing existing superblock
};
fn fsconfig(fd: i32, cmd: FsconfigCommand, key: ?[*:0]const u8, val: ?*const anyopaque, aux: i32) !void {
    const rc = std.os.linux.syscall5(.fsconfig, @intCast(fd), @intFromEnum(cmd), @intFromPtr(key), @intFromPtr(val), @bitCast(@as(isize, aux)));
    const signed: isize = @bitCast(rc);
    const code: std.posix.E = @enumFromInt(if (signed > -4096 and signed < 0) -signed else 0);
    return switch (code) {
        .SUCCESS => {},
        .ACCES => error.AccessDenied,
        .BADF => unreachable,
        .BUSY => error.DeviceBusy,
        .FAULT => unreachable,
        .INVAL => unreachable,
        .LOOP => error.SymLinkLoop,
        .NAMETOOLONG => error.NameTooLong,
        .NOENT => error.FileNotFound,
        .NOMEM => error.SystemResources,
        .NOTBLK => error.NotBlk,
        .NOTDIR => error.NotDir,
        .OPNOTSUPP => error.OperationNotSupported,
        .NXIO => error.MajorOutOfRange,
        .PERM => error.PermissionDenied,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

fn fsmount(fd: i32, cloexec: bool, mount_attrs: u32) !i32 {
    const rc = std.os.linux.syscall3(.fsmount, @bitCast(@as(isize, fd)), @intFromBool(cloexec), mount_attrs);
    const signed: isize = @bitCast(rc);
    const code: std.posix.E = @enumFromInt(if (signed > -4096 and signed < 0) -signed else 0);
    return switch (code) {
        .SUCCESS => @intCast(signed),
        .BUSY => error.DeviceBusy,
        .FAULT => unreachable,
        .INVAL => unreachable,
        .MFILE, .NFILE => error.ProcessFdQuotaExceeded,
        .NOMEM => error.SystemResources,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

fn mountErr(fd: i32, comptime logger: type) void {
    var buffer: [8192]u8 = undefined;
    o: while (true) { //read all the messages
        const n: usize = while (true) { //read may be interupted
            const rc = std.os.linux.read(fd, &buffer, buffer.len);
            const signed: isize = @bitCast(rc);
            const code: std.posix.E = @enumFromInt(if (signed > -4096 and signed < 0) -signed else 0);
            switch (code) {
                .SUCCESS => break rc,
                .NODATA => break :o,
                .INTR => continue,
                else => unreachable,
            }
        };

        switch (buffer[0]) {
            'e' => logger.err("{s}\n", .{buffer[1..n]}),
            'i' => logger.info("{s}\n", .{buffer[1..n]}),
            'w' => logger.warn("{s}\n", .{buffer[1..n]}),
            else => unreachable,
        }
    }
}

const MoveMountFlags = packed struct(u32) {
    f_symlinks: bool = false, // Follow symlinks on from path
    f_automounts: bool = false, // Follow automounts on from path
    f_empty_path: bool = false, // Empty from path permitted
    __padding: u1 = 0,
    t_symlinks: bool = false, // Follow symlinks on to path
    t_automounts: bool = false, // Follow automounts on to path
    t_empty_path: bool = false, // Empty to path permitted
    __padding2: u1 = 0,
    set_group: bool = false, // Set sharing group instead
    beneath: bool = false, // Mount beneath top mount
    __padding3: u22 = 0,
};
fn move_mount(from_dirfd: i32, from_pathname: [*:0]const u8, to_dirfd: i32, to_pathname: [*:0]const u8, flags: MoveMountFlags) !void {
    const rc = std.os.linux.syscall5(
        .move_mount,
        @bitCast(@as(isize, from_dirfd)),
        @intFromPtr(from_pathname),
        @bitCast(@as(isize, to_dirfd)),
        @intFromPtr(to_pathname),
        @as(u32, @bitCast(flags)),
    );
    const signed: isize = @bitCast(rc);
    const code: std.posix.E = @enumFromInt(if (signed > -4096 and signed < 0) -signed else 0);
    return switch (code) {
        .SUCCESS => {},
        .ACCES => error.AccessDenied,
        .FAULT => unreachable,
        .INVAL => unreachable,
        .OPNOTSUPP => error.OperationNotSupported,
        .LOOP => error.SymLinkLoop,
        .NAMETOOLONG => error.NameTooLong,
        .NOENT => error.FileNotFound,
        .NOMEM => error.SystemResources,
        .NOTDIR => error.NotDir,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

const OpenTreeFlags = packed struct(u32) {
    clone: bool = false,
    __padding: u18 = 0,
    cloexec: bool = false,
    __padding2: u12 = 0,
};
fn open_tree(dirfd: i32, pathname: [*:0]const u8, flags: OpenTreeFlags) !i32 {
    const rc = std.os.linux.syscall3(.open_tree, @bitCast(@as(isize, dirfd)), @intFromPtr(pathname), @as(u32, @bitCast(flags)));
    const signed: isize = @bitCast(rc);
    const code: std.posix.E = @enumFromInt(if (signed > -4096 and signed < 0) -signed else 0);
    return switch (code) {
        .SUCCESS => @intCast(signed),
        .ACCES => error.AccessDenied,
        .PERM => error.PermissionDenied,
        .BADF => unreachable,
        .FAULT => unreachable,
        .INVAL => unreachable,
        .LOOP => error.SymLinkLoop,
        .NAMETOOLONG => error.NameTooLong,
        .NOENT => error.FileNotFound,
        .NOMEM => error.SystemResources,
        .NOTDIR => error.NotDir,
        else => |err| std.posix.unexpectedErrno(err),
    };
}

pub fn mount(src: [*:0]const u8, dst: [*:0]const u8, fstype: [*:0]const u8, options: []const [2][*:0]const u8, flags: []const [*:0]const u8) !void {
    const logger = std.log.scoped(.mount);

    const sfd = try fsopen(fstype, true);
    mountErr(sfd, logger);
    defer std.posix.close(sfd);

    try fsconfig(sfd, .SetString, "source", src, 0);
    mountErr(sfd, logger);

    for (options) |option| {
        try fsconfig(sfd, .SetString, option[0], option[1], 0);
        mountErr(sfd, logger);
    }
    for (flags) |flag| {
        try fsconfig(sfd, .SetFlag, flag, null, 0);
        mountErr(sfd, logger);
    }

    try fsconfig(sfd, .CmdCreate, null, null, 0);
    mountErr(sfd, logger);

    const mountobj = try fsmount(sfd, true, 0);
    defer std.posix.close(mountobj);

    try move_mount(mountobj, "", std.fs.cwd().fd, dst, .{ .f_empty_path = true });
    mountErr(sfd, logger);
}

pub fn bind(src: [*:0]const u8, dst: [*:0]const u8) !void {
    const f = try open_tree(std.fs.cwd().fd, src, .{ .cloexec = true, .clone = true });
    defer std.posix.close(f);
    try move_mount(f, "", std.fs.cwd().fd, dst, .{ .f_empty_path = true });
}
