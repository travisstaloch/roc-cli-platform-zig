const std = @import("std");
const str = @import("str");
const RocStr = str.RocStr;
const list = @import("list.zig");
const RocList = list.RocList;
const testing = std.testing;
const expectEqual = testing.expectEqual;
const expect = testing.expect;
const maxInt = std.math.maxInt;

comptime {
    // This is a workaround for https://github.com/ziglang/zig/issues/8218
    // which is only necessary on macOS.
    //
    // Once that issue is fixed, we can undo the changes in
    // 177cf12e0555147faa4d436e52fc15175c2c4ff0 and go back to passing
    // -fcompiler-rt in link.rs instead of doing this. Note that this
    // workaround is present in many host.zig files, so make sure to undo
    // it everywhere!
    const builtin = @import("builtin");
    if (builtin.os.tag == .macos) {
        _ = @import("compiler_rt");
    }
}

const mem = std.mem;
const Allocator = mem.Allocator;

extern fn roc__mainForHost_1_exposed_generic([*]u8) void;
extern fn roc__mainForHost_size() i64;
extern fn roc__mainForHost_1__Fx_caller(*const u8, [*]u8, [*]u8) void;
extern fn roc__mainForHost_1__Fx_size() i64;
extern fn roc__mainForHost_1__Fx_result_size() i64;

const Align = 2 * @alignOf(usize);
extern fn malloc(size: usize) callconv(.C) ?*align(Align) anyopaque;
extern fn realloc(c_ptr: [*]align(Align) u8, size: usize) callconv(.C) ?*anyopaque;
extern fn free(c_ptr: [*]align(Align) u8) callconv(.C) void;
extern fn memcpy(dst: [*]u8, src: [*]u8, size: usize) callconv(.C) void;
extern fn memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void;

const DEBUG: bool = false;

export fn roc_alloc(size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        var ptr = malloc(size);
        const stdout = std.io.getStdOut().writer();
        stdout.print("alloc:   {d} (alignment {d}, size {d})\n", .{ ptr, alignment, size }) catch unreachable;
        return ptr;
    } else {
        return malloc(size);
    }
}

export fn roc_realloc(c_ptr: *anyopaque, new_size: usize, old_size: usize, alignment: u32) callconv(.C) ?*anyopaque {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("realloc: {d} (alignment {d}, old_size {d})\n", .{ c_ptr, alignment, old_size }) catch unreachable;
    }

    return realloc(@alignCast(Align, @ptrCast([*]u8, c_ptr)), new_size);
}

export fn roc_dealloc(c_ptr: *anyopaque, alignment: u32) callconv(.C) void {
    if (DEBUG) {
        const stdout = std.io.getStdOut().writer();
        stdout.print("dealloc: {d} (alignment {d})\n", .{ c_ptr, alignment }) catch unreachable;
    }

    free(@alignCast(Align, @ptrCast([*]u8, c_ptr)));
}

export fn roc_panic(c_ptr: *const anyopaque, tag_id: u32) callconv(.C) noreturn {
    _ = tag_id;

    const stderr = std.io.getStdErr().writer();
    const msg = @ptrCast([*:0]const u8, c_ptr);
    stderr.print("Application crashed with message\n\n    {s}\n\nShutting down\n", .{msg}) catch unreachable;
    std.process.exit(0);
}

export fn roc_memcpy(dst: [*]u8, src: [*]u8, size: usize) callconv(.C) void {
    return memcpy(dst, src, size);
}

export fn roc_memset(dst: [*]u8, value: i32, size: usize) callconv(.C) void {
    return memset(dst, value, size);
}

const Unit = extern struct {};

// WARNING: don't change this back to `pub extern fn main() callconv(.C) u8` as
// that breaks zig's cli argument handling, maing std.process.args() yield in 0 args.
pub fn main() u8 {
    // The size might be zero; if so, make it at least 8 so that we don't have a nullptr
    const size = std.math.max(@intCast(usize, roc__mainForHost_size()), 8);
    const raw_output = roc_alloc(@intCast(usize, size), @alignOf(u64)).?;
    var output = @ptrCast([*]u8, raw_output);

    defer {
        roc_dealloc(raw_output, @alignOf(u64));
    }

    var timer = std.time.Timer.start() catch unreachable;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    roc__mainForHost_1_exposed_generic(output);

    const closure_data_pointer = @ptrCast([*]u8, output);

    call_the_closure(allocator, closure_data_pointer);

    const nanos = timer.read();
    const seconds = (@intToFloat(f64, nanos) / 1_000_000_000.0);

    const stderr = std.io.getStdErr().writer();
    stderr.print("runtime: {d:.3}ms\n", .{seconds * 1000}) catch unreachable;

    return 0;
}

fn to_seconds(tms: std.os.timespec) f64 {
    return @intToFloat(f64, tms.tv_sec) + (@intToFloat(f64, tms.tv_nsec) / 1_000_000_000.0);
}

fn call_the_closure(allocator: Allocator, closure_data_pointer: [*]u8) void {

    // The size might be zero; if so, make it at least 8 so that we don't have a nullptr
    const size = std.math.max(roc__mainForHost_1__Fx_result_size(), 8);
    const raw_output = allocator.allocAdvanced(u8, @alignOf(u64), @intCast(usize, size), .at_least) catch unreachable;
    var output = @ptrCast([*]u8, raw_output);

    defer {
        allocator.free(raw_output);
    }

    const flags: u8 = 0;

    roc__mainForHost_1__Fx_caller(&flags, closure_data_pointer, output);

    // The closure returns result, nothing interesting to do with it
    return;
}

pub export fn roc_fx_putInt(int: i64) i64 {
    const stdout = std.io.getStdOut().writer();
    stdout.print("{d}\n", .{int}) catch unreachable;
    return 0;
}

// TODO buffered writer
export fn roc_fx_putLine(rocPath: *str.RocStr) callconv(.C) void {
    const stdout = std.io.getStdOut().writer();
    _ = stdout.write(rocPath.asSlice()) catch unreachable;
    _ = stdout.write("\n") catch unreachable;
}

// TODO buffered writer
export fn roc_fx_putLineStderr(rocPath: *str.RocStr) callconv(.C) void {
    const stderr = std.io.getStdErr().writer();
    _ = stderr.write(rocPath.asSlice()) catch unreachable;
    _ = stderr.write("\n") catch unreachable;
}

const GetInt = extern struct {
    value: i64,
    is_error: bool,
};

comptime {
    if (@sizeOf(usize) == 8) {
        @export(roc_fx_getInt_64bit, .{ .name = "roc_fx_getInt" });
    } else {
        @export(roc_fx_getInt_32bit, .{ .name = "roc_fx_getInt" });
    }
    @export(roc_fx_putLine, .{ .name = "roc_fx_stdoutLine" });
    @export(roc_fx_putLineStderr, .{ .name = "roc_fx_stderrLine" });
}

fn roc_fx_getInt_64bit() callconv(.C) GetInt {
    if (roc_fx_getInt_help()) |value| {
        const get_int = GetInt{ .is_error = false, .value = value };
        return get_int;
    } else |err| switch (err) {
        error.InvalidCharacter => {
            return GetInt{ .is_error = true, .value = 0 };
        },
        else => {
            return GetInt{ .is_error = true, .value = 0 };
        },
    }

    return 0;
}

fn roc_fx_getInt_32bit(output: *GetInt) callconv(.C) void {
    if (roc_fx_getInt_help()) |value| {
        const get_int = GetInt{ .is_error = false, .value = value, .error_code = false };
        output.* = get_int;
    } else |err| switch (err) {
        error.InvalidCharacter => {
            output.* = GetInt{ .is_error = true, .value = 0, .error_code = false };
        },
        else => {
            output.* = GetInt{ .is_error = true, .value = 0, .error_code = true };
        },
    }

    return;
}

fn roc_fx_getInt_help() !i64 {
    const stdout = std.io.getStdOut().writer();
    stdout.print("Please enter an integer\n", .{}) catch unreachable;

    const stdin = std.io.getStdIn().reader();
    var buf: [40]u8 = undefined;

    const line: []u8 = (try stdin.readUntilDelimiterOrEof(&buf, '\n')) orelse "";

    return std.fmt.parseInt(i64, line, 10);
}

// a result with and empty (void) error type
fn RocResult(comptime T: type) type {
    return RocResultUnion(T, void);
}

fn RocResultUnion(comptime T: type, comptime E: type) type {
    return extern struct {
        payload: extern union { ok: T, err: E },
        tag: u8,
        pub const len = @sizeOf(@This());
    };
}

const ResultRocStr = RocResult(RocStr);
const ResultRocList = RocResult(RocList);

const ResultVoid = extern struct {
    tag: u8,
    pub const len = 1;
};

// the size of this structure must be kept in sync with the structures
// produced by roc like InternalFile.ReadError
const RocFileReadResult = RocResultUnion(RocList, ReadErr);

// FIXME: file-read-errors.roc always prints 'other unhandled error' for all errors
// not sure what is causing this. perhaps the ReadErr layout still isn't
// correct?
pub const ReadErr = extern struct {
    code: i32,
    message: RocStr,
    tag: u8,

    comptime {
        std.debug.assert(@sizeOf(ReadErr) == 40);
    }

    pub fn init(comptime tag: Tag, mpayload: ?Payload) ReadErr {
        const payload = mpayload orelse Payload{ .code = -1, .message = RocStr.empty() };
        return .{ .tag = @enumToInt(tag), .code = payload.code, .message = payload.message };
    }
    pub const Payload = extern struct {
        code: i32,
        message: RocStr,
    };
    pub const Tag = enum(u8) {
        Interrupted,
        InvalidFilename,
        NotFound,
        OutOfMemory,
        PermissionDenied,
        StaleNetworkFileHandle,
        TimedOut,
        TooManyHardlinks,
        TooManySymlinks,
        Unsupported,
        Unrecognized,
    };
};

// credit and thanks to https://github.com/bhansconnect for getting this working
pub export fn roc_fx_fileReadBytes(path: *RocList) callconv(.C) RocFileReadResult {
    // std.debug.print("Called fileReadBytes\n", .{});
    if (path.bytes) |path_ptr| {
        const path_slice = path_ptr[0..path.len()];
        // var realpathbuf: [256]u8 = undefined;
        // const realpath = std.fs.cwd().realpath(".", &realpathbuf);
        // std.debug.print("path '{s}' realpath {s}\n", .{ path_slice, realpath });
        // TODO better error handling. this doesn't check the error, assuming FileNotFound
        const file = std.fs.cwd().openFile(path_slice, .{}) catch return .{
            .payload = .{ .err = ReadErr.init(.NotFound, null) },
            .tag = 0,
        };
        if (file.handle == -1) return .{
            .payload = .{ .err = ReadErr.init(.NotFound, null) },
            .tag = 0,
        };
        // NOTE this defer must come after early return if fd == -1. otherwise boom
        defer file.close();
        const stat = file.stat() catch return .{
            .payload = .{ .err = ReadErr.init(.NotFound, null) },
            .tag = 0,
        };
        // std.debug.print("stat.size {}\n", .{stat.size});
        var roclist = RocList.allocate(@alignOf(usize), stat.size, 1);
        if (roclist.bytes) |bytes| {
            const slice = bytes[0..stat.size];
            const amt = file.readAll(slice) catch return .{
                .payload = .{ .err = ReadErr.init(.NotFound, null) },
                .tag = 0,
            };
            // TODO: handle error here
            std.debug.assert(amt == stat.size);

            return .{
                .payload = .{ .ok = roclist },
                .tag = 1,
            };
        }
    }
    return .{
        .payload = .{ .err = ReadErr.init(.InvalidFilename, null) },
        .tag = 0,
    };
}

// NOTE: when run with `roc file.roc` arg 0 will be '/proc/self/fd/3' on linux
// because the exe is compiled in memory and then launchd from the roc run executable.
// When run with `roc build file.roc && ./file` arg 0 will be normal.
export fn roc_fx_args() callconv(.C) RocList {
    const rocstr_alignment = @alignOf(RocStr);
    const rocstr_size = @sizeOf(RocStr);
    const allocator = std.heap.c_allocator;
    // FIXME memory leak
    const args = std.process.argsAlloc(allocator) catch unreachable;
    var roclist = RocList.empty();
    for (args) |arg| {
        // std.debug.print("roc_fx_args() arg {s}\n", .{ arg });
        var rocstr = RocStr.fromSlice(std.mem.span(arg));
        roclist = list.listAppend(
            roclist,
            rocstr_alignment,
            @ptrCast([*]u8, &rocstr),
            rocstr_size,
            .InPlace,
        );
    }
    return roclist;
}

export fn roc_fx_envVar(var_name: *RocStr) callconv(.C) ResultRocStr {
    const slice = var_name.asSlice();
    // FIXME memory leak
    const contents = std.process.getEnvVarOwned(std.heap.c_allocator, slice) catch return .{
        .payload = .{ .err = {} },
        .tag = 0,
    };

    return .{
        .payload = .{ .ok = RocStr.fromSlice(contents) },
        .tag = 1,
    };
}

export fn roc_fx_cwd() callconv(.C) RocList {
    var buf: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    // FIXME handle error.NameTooLong - use std.process.getCwdAlloc
    const cwd = std.process.getCwd(&buf) catch return RocList.empty();
    return RocList.fromSlice(u8, cwd);
}

export fn roc_fx_setCwd(path: *RocList) callconv(.C) ResultVoid {
    var tag: u8 = 1;
    if (path.bytes) |bytes| {
        // std.debug.print("called roc_fx_setCwd({s})\n", .{bytes[0..path.length]});
        std.process.changeCurDir(bytes[0..path.length]) catch {
            tag = 0;
        };
    } else tag = 0;

    return .{
        .tag = tag,
    };
}

// NOTE: when run with `roc file.roc` arg 0 will be '/proc/self/fd/3' on linux
// because the exe is compiled in memory and then launchd from the roc run executable.
// When run with `roc build file.roc && ./file` arg 0 will be normal.
export fn roc_fx_exePath() callconv(.C) ResultRocList {
    // std.debug.print("called roc_fx_exePath()\n", .{});
    const args = std.process.argsAlloc(std.heap.c_allocator) catch return .{
        .payload = .{ .err = {} },
        .tag = 0,
    };
    const arg0 = std.mem.span(args[0]);
    return .{
        .payload = .{ .ok = RocList.fromSlice(u8, arg0) },
        .tag = 1,
    };
}
