# zig-linux-mount
Simple one file zig library for mounting on linux

It does not spawn child processes, it uses the modern linux mount api.

# logs
Info, warning and error messages are loged through `std.log`, in the `mount` scope, and therefore you can set what level do you want to see through `std.option`
```zig
pub const std_options: std.Options=.{
  log_scope_levels=&.{
    .{.scope=.mount, .level=.err},
  }
};
```

# Examples
## overlay
```sh
mount name /mountpoint -t overlay  -o ro,relatime,lowerdir=/lower,upperdir=/upper,workdir=/work
```
```zig
try mount.mount("name", "/mountpoint", "overlay", &.{
    .{ "lowerdir", "/lower" },
    .{ "upperdir", "/upper" },
    .{ "workdir", "/work" },
}, &.{"ro", "relatime"});
```
## bind
```sh
mount /src /target --bind
```
```zig
try mount.bind("/src", "/target");
```
