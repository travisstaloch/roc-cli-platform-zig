# cli-platform-zig
An experimental [roc lang](https://github.com/roc-lang) [zig](https://ziglang.org) cli platform.  Adapated from [the rust cli platform](https://github.com/roc-lang/roc/tree/main/examples/cli/cli-platform).  

# dependencies
- a roc compiler in PATH
- zig version 0.9.1 in PATH

# usage
```console
./build.sh
```

# notes
- copied to platform/ from roc repo
  - examples/cli/tui-platform/host.zig
  - examples/cli/cli-platform/main.roc
  - examples/cli/cli-platform/*.roc
  - crates/compiler/builtins/bitcode/src/{utils,list}.zig

# status
see [platform-test/main.roc](platform-test/main.roc)
  - [x] Stdout.line working
  - [ ] wip - File.readBytes functional but not complete

# todo
  - [ ] make `platform/host.zig/RocResult#payload` a union T,E to sync with `platform/InternalFile.ReadError`
      - discussion:  https://roc.zulipchat.com/#narrow/stream/347488-roctoberfest/topic/Alternative.20platform.20languages/near/303105460

