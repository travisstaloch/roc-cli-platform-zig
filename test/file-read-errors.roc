app "file-read-errors"
    packages { pf: "../platform/main.roc" }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Program.{ Program },
        pf.Task,
        pf.File.{ ReadErr },
        pf.Path,
    ]
    provides [main] to pf

readErrToStr : ReadErr -> Str
readErrToStr = \e ->
    when e is
        NotFound -> "NotFound"
        Interrupted -> "Interrupted"
        InvalidFilename -> "InvalidFilename"
        PermissionDenied -> "PermissionDenied"
        TooManySymlinks -> "TooManySymlinks"
        TooManyHardlinks -> "TooManyHardlinks"
        TimedOut -> "TimedOut"
        StaleNetworkFileHandle -> "StaleNetworkFileHandle"
        OutOfMemory -> "OutOfMemory"
        Unsupported -> "Unsupported"
        Unrecognized code message ->
            codestr = Num.toStr code
            "Unrecognized code: \(codestr) message: \(message)"

main : Program
main = Program.withArgs \args ->
    task =
        path = List.get args 1 |> Result.withDefault "empty" |> Path.fromStr
        _ <- path
            |> File.debugReadErr
            |> Task.onFail (\e ->
                FileReadErr _ readerr = e
                errstr = readErrToStr readerr
                _ <- Stdout.line errstr |> Task.await
                Task.fail e
            )
            |> Task.await   
        Stdout.line ""

    Task.attempt task \result ->
        when result is
            Ok {} ->
                Task.succeed {}
                |> Program.exit 0

            Err _ ->
                Stderr.line ""
                |> Program.exit 1
