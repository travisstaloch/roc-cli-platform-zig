# using this script makes comiler errors easier to read. 
# when roc prints a compile error, it has no color
zig build-exe platform/host.zig --pkg-begin str ../roc/crates/compiler/builtins/bitcode/src/str.zig --pkg-end -lc
