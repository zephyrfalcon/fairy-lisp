// repl.d

import std.stdio;
import errors;
import interpreter;
import reader;
import types;

class REPL {

    Interpreter intp;
    dstring prompt = "> ";

    this() {
        this.intp = new Interpreter();
    }
    this(Interpreter intp) {
        this.intp = intp;
    }

    void MainLoop() {
        writeln("Welcome to Fairy Lisp 0.1.");

        auto rd = new FileReader(stdin);
        while (true) {
            LispObject expr;
            write(this.prompt);

            try {
                expr = rd.Read();
            } catch (NoInputException e) {
                break;
            } catch (Exception e) {
                writeln("An error occurred.");  // FIXME
                this.intp.callstack.Clear();
                continue;
            }

            try {
                expr = this.intp.MacroExpand(expr, this.intp.global_env);
                LispObject result = this.intp.EvalExpr(expr, this.intp.global_env);
                writefln("%s", result.Repr());
            } catch (Exception e) {
                writeln("ERROR: ", e.msg);
                this.intp.callstack.Print();
                writeln(e);  // includes traceback (make this an option?)
                this.intp.callstack.Clear();
            }
        }
    }

}

