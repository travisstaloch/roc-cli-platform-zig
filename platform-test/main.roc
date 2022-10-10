app "platform-main"
    packages { pf: "../platform/main.roc" }
    imports [
        pf.Stdout, pf.Program.{ Program },
        pf.Task, 
        pf.Path, 
        pf.File.{ 
            # readUtf8, 
         }, 
        
    ]
    provides [main] to pf

main : Program
main =
    pathstr = "platform-test/1.txt"
    path = Path.fromStr pathstr
    task = 
        _ <- Task.await (Stdout.line "this gets printed")
        contents <- Task.await (File.readBytes path)
        _ <- Task.await (Stdout.line ((Str.fromUtf8 contents) # silently fails, breaks subsequent prints
            |> (Result.withDefault "oops")))
        Stdout.line "this doesn't get printed"
    Program.quick task
