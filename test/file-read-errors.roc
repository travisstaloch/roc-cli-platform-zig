app "file-read-errors"
    packages { pf: "../platform/main.roc" }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Program.{ Program },
        pf.Task,
        pf.File,
        pf.Path,
    ]
    provides [main] to pf

main : Program
main = Program.withArgs \args ->
    task =
        arg1 = List.get args 1 |> Result.withDefault "empty"
        _ <- arg1
            |> Path.fromStr
            |> File.debugReadErr
            |> Task.onFail (\e ->
                _ <- (when e is
                    FileReadErr _ NotFound ->  Stdout.line "NotFound"
                    FileReadErr _ Interrupted ->  Stdout.line "Interrupted"
                    FileReadErr _ InvalidFilename ->  Stdout.line "InvalidFilename"
                    FileReadErr _ PermissionDenied ->  Stdout.line "PermissionDenied"
                    FileReadErr _ TooManySymlinks ->  Stdout.line "TooManySymlinks"
                    FileReadErr _ TooManyHardlinks ->  Stdout.line "TooManyHardlinks"
                    FileReadErr _ TimedOut ->  Stdout.line "TimedOut"
                    FileReadErr _ StaleNetworkFileHandle ->  Stdout.line "StaleNetworkFileHandle"
                    FileReadErr _ OutOfMemory ->  Stdout.line "OutOfMemory"
                    FileReadErr _ Unsupported ->  Stdout.line "Unsupported"
                    FileReadErr _ (Unrecognized code message) ->
                        codestr = Num.toStr code
                        Stdout.line "Unrecognized code \(codestr) message \(message)"
                    ) |> Task.await
                Task.fail e) |> Task.await
        # TODO remove this - will never be reached. not sure how to
        # str = Str.fromUtf8 x |> Result.withDefault ""
        Stdout.line ""

    Task.attempt task \result ->
        when result is
            Ok {} ->
                Task.succeed {}
                |> Program.exit 0
            Err _ ->
                Stderr.line ""
                |> Program.exit 1

