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
        nonpath = "not-a-file"
        bytes <- nonpath
            |> Path.fromStr
            |> File.readBytes
            |> Task.onFail (\e ->
                _ <- (when e is
                    # FIXME: this always prints 'other unhandled error'.  
                    # not sure what is causing this. perhaps the ReadErr layout still isn't
                    # correct?  Or maybe this isn't the right syntax for matching InternalFile.ReadErr
                    Err ReadErr NotFound ->  Stderr.line "not found"
                    Err ReadErr Interrupted ->  Stderr.line "Interrupted"
                    Err ReadErr InvalidFilename ->  Stderr.line "InvalidFilename"
                    Err ReadErr PermissionDenied ->  Stderr.line "PermissionDenied"
                    Err ReadErr TooManySymlinks ->  Stderr.line "TooManySymlinks"
                    Err ReadErr TooManyHardlinks ->  Stderr.line "TooManyHardlinks"
                    Err ReadErr TimedOut ->  Stderr.line "TimedOut"
                    Err ReadErr StaleNetworkFileHandle ->  Stderr.line "StaleNetworkFileHandle"
                    Err ReadErr OutOfMemory ->  Stderr.line "OutOfMemory"
                    Err ReadErr Unsupported ->  Stderr.line "Unsupported"
                    Err ReadErr (Unrecognized code message) ->
                        codestr = Num.toStr code
                        Stderr.line "Unrecognized code \(codestr) message \(message)"
                    _  -> Stderr.line "other unhandled error"
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

