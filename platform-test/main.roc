app "platform-main"
    packages { pf: "../platform/main.roc" }
    imports [
        pf.Stdout, pf.Program.{ Program },
        pf.Task, 
        pf.Path, 
        pf.File,
    ]
    provides [main] to pf

main : Program
main =
    pathstr = "platform-test/1.txt"
    path = Path.fromStr pathstr
    task = 
        _ <- Task.await (Stdout.line (Path.display path))
        contents <- Task.await (File.readUtf8 path)
        raw = Str.toUtf8 contents
        head = List.takeFirst raw 50
        shead = Result.withDefault (Str.fromUtf8 head) ""
        _ <- Task.await (Stdout.line shead)
        Stdout.line "...truncated"
    Program.quick task
