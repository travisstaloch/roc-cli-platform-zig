app "platform-main"
    packages { pf: "../platform/main.roc" }
    imports [
        pf.Stdout,
        pf.Stderr,
        pf.Program.{ Program },
        pf.Task,
        pf.Path,
        pf.File,
        pf.Env,
    ]
    provides [main] to pf

main : Program
main = Program.withArgs \args ->
    pathstr = "platform-test/1.txt"
    path = Path.fromStr pathstr
    task = 
        _ <- Task.await (Stdout.line (Path.display path))
        contents <- Task.await (File.readUtf8 path)
        raw = Str.toUtf8 contents
        head = List.takeFirst raw 50
        shead = Result.withDefault (Str.fromUtf8 head) ""
        _ <- Task.await (Stdout.line shead)
        _ <- Task.await (Stdout.line "...truncated")

        arg0 = List.get args 0 |> Result.withDefault "empty"
        _ <- Task.await (Stdout.line "cli arg 0: \(arg0)")

        envkey = "foo"
        Task.attempt (Env.var envkey) \r ->
            when r is
                Err _ -> Stderr.line "error env:\(envkey) not found"
                Ok envval -> Stdout.line "env:\(envkey)=\(envval) - this line goes to stderr"

    Task.attempt task \result ->
        when result is
            Ok {} ->
                Task.succeed {}
                |> Program.exit 0
            Err _ ->
                Stderr.line ""
                |> Program.exit 1