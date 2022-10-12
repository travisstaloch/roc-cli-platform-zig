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
    task = 
        # Stdout/Stderr.line
        # File.readBytes/readUtf8
        path = "platform-test/main.roc"
        contents <- path |> Path.fromStr |> File.readUtf8 |> Task.await
        raw = Str.toUtf8 contents
        head = List.takeFirst raw 35 |> Str.fromUtf8 |> Result.withDefault ""
        _ <- Stdout.line "----\nFile.readUtf8 \(path):\n----\n\(head)...(truncated)\n----" |> Task.await

        nonpath = "not-a-file"
        contents2 <- nonpath
            |> Path.fromStr
            |> File.readUtf8
            |> Task.onFail (\_ -> Task.succeed "Not Found") #TODO print error tag somehow
            |> Task.await
        _ <- Stdout.line "\(nonpath):               \(contents2)" |> Task.await

        # Program.withArgs
        arg0 = List.get args 0 |> Result.withDefault "empty"
        _ <- Stdout.line "cli arg 0:                \(arg0)" |> Task.await
        arg1 = List.get args 1 |> Result.withDefault "empty"
        _ <- Stdout.line "cli arg 1:                \(arg1)" |> Task.await
        
        # Env.exePath
        exepathp <- Env.exePath |> Task.await
        exepath = Path.display exepathp
        _ <- Stdout.line "Env.exePath:              \(exepath)" |> Task.await
        
        # Env.cwd, Env.setCwd
        cwdp <- Env.cwd |> Task.await
        cwd = Path.display cwdp
        _ <- Stdout.line "Env.cwd:                  \(cwd)" |> Task.await
        _ <- Env.setCwd (Path.fromStr "/tmp") |> Task.await
        cwdp2 <- Env.cwd |> Task.await
        cwd2 = Path.display cwdp2
        _ <- Stdout.line "Env.setCwd /tmp, Env.cwd: \(cwd2)" |> Task.await

        # Env.var
        envkey = "foo"
        Env.var envkey |> Task.attempt \r ->
            when r is
                Err _ ->     Stderr.line "Env.var:                  \(envkey)=not found - this line goes to stderr"
                Ok envval -> Stdout.line "Env.var:                  \(envkey)=\(envval)"

    Task.attempt task \result ->
        when result is
            Ok {} ->
                Task.succeed {}
                |> Program.exit 0
            Err _ ->
                Stderr.line ""
                |> Program.exit 1
