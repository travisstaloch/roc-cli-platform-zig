# cli-platform-zig
An experimental [roc lang](https://github.com/roc-lang) cli platform in [zig](https://ziglang.org).  Adapated from roc's [rust cli platform](https://github.com/roc-lang/roc/tree/main/examples/cli/cli-platform).  

# dependencies
- a roc compiler in PATH
- zig version 0.9.1 in PATH

# usage
1. clone this repo
2. reference [platform/main.roc](platform/main.roc) in your roc app like this:
   `packages { pf: "path/to/platform/main.roc" }` (see [platform-test/main.roc](platform-test/main.roc) for an example)

# test
```console
./test.sh # builds and runs platform-test/main.roc
```
# status
  - [x] Stdout.line, Stderr.line
  - [x] File.readBytes - with initial error handling *wip
  - [x] Process.withArgs
  - [x] Env.{var,cwd,setCwd,exePath}

see [platform-test/main.roc](platform-test/main.roc) to see what works.  

# notes
- copied to platform/ from roc repo
  - examples/cli/tui-platform/host.zig
  - examples/cli/cli-platform/main.roc
  - examples/cli/cli-platform/*.roc
  - crates/compiler/builtins/bitcode/src/{utils,list}.zig

# todo
- File.write, delete, ...

# contributors
 - bhansconnect@github