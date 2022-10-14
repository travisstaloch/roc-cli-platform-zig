app "main"
    packages { pf: "../platform/main.roc" }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Program.{ Program },
        pf.Task,
        pf.Path,
        pf.File,
    ]
    provides [main] to pf

main : Program
main = Program.withArgs \_ ->
    task =
        # nonpath = "not-a-file"
        nonpath = "foo" # FIXME foo returns an Unrecognized
        bytes <- nonpath
            |> Path.fromStr
            |> File.readBytes
            |> Task.onFail (\e ->
                _ <- (when e is
                    FileReadErr _ NotFound ->  Stderr.line "not found"
                    FileReadErr _ Interrupted ->  Stderr.line "Interrupted"
                    FileReadErr _ InvalidFilename ->  Stderr.line "InvalidFilename"
                    FileReadErr _ PermissionDenied ->  Stderr.line "PermissionDenied"
                    FileReadErr _ TooManySymlinks ->  Stderr.line "TooManySymlinks"
                    FileReadErr _ TooManyHardlinks ->  Stderr.line "TooManyHardlinks"
                    FileReadErr _ TimedOut ->  Stderr.line "TimedOut"
                    FileReadErr _ StaleNetworkFileHandle ->  Stderr.line "StaleNetworkFileHandle"
                    FileReadErr _ OutOfMemory ->  Stderr.line "OutOfMemory"
                    FileReadErr _ Unsupported ->  Stderr.line "Unsupported"
                    FileReadErr _ (Unrecognized code message) ->
                        codestr = Num.toStr code
                        Stderr.line "Unrecognized code \(codestr) message \(message)"
                    ) |> Task.await
                Task.fail e) |> Task.await
        str = Str.fromUtf8 bytes |> Result.withDefault ""
        Stdout.line "\(str)"

    Task.attempt task \result ->
        when result is
            Ok {} ->
                Task.succeed {}
                |> Program.exit 0
            Err _ ->
                Stderr.line ""
                |> Program.exit 1

