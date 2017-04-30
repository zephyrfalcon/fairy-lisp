import std.stdio;
import interpreter;
import repl;

void main(string[] args)
{
    auto intp = new Interpreter();
    if (args.length > 1) {
        foreach(filename; args[1..$]) {
            intp.RunFile(filename);
        }
        return;
    }

    auto repl = new REPL(intp);
    repl.MainLoop();
}

