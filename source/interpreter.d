// interpreter.d

import std.array;
import std.conv;
import std.format;
import std.stdio;

import callstack;
import errors;
import reader;
import stackframe;
import types;

class Interpreter {
    dstring prompt = "> ";
    CallStack callstack;
    LispEnvironment builtin_env;
    LispEnvironment global_env;
    // TODO: debug options

    this() {
        this.callstack = new CallStack();
        this.builtin_env = new LispEnvironment();
        this.global_env = new LispEnvironment(this.builtin_env);
        this.LoadBuiltins();
        // TODO: autoload code
    }

    void LoadBuiltins() {
        this.builtin_env.Set("true", TRUE());
        this.builtin_env.Set("false", FALSE());
        // TODO: load types
        // TODO: load builtin functions
    }

    LispObject EvalAtomic(LispObject expr, LispEnvironment env) {
        // symbols are looked up
        if (auto sym = cast(LispSymbol) expr) {
            LispObject value = env.Get(sym.value);
            return value;
        } else {
            // everything else evaluates to itself
            return expr;
        }
    }

    void EvalStep() {
        StackFrame top = this.callstack.Top();

        if (top.IsDone()) {
            if (top.is_atomic) {
                LispObject value = top.evaluated[0];
                this.callstack.Collapse(value);
            } else {
                // if we're done evaluating all the parts, we can call the
                // function.
                throw new NotImplementedError("function calls");
            }
            return;
        } 

        if (top.is_atomic) {
            assert(top.evaluated.length == 0, "this is not supposed to happen");
            LispObject result = this.EvalAtomic(top.original_expr, top.env);
            if (top.aux_data !is null) {
                // top.aux_data.Receive(result);
            } else {
                top.evaluated ~= result;
            }
        } else {
            // it's a compound expression
            throw new NotImplementedError("compound expressions");
        }
    }

    LispObject Eval() {
        while (true) {
            // TODO: show call stack if debug option set
            if (this.callstack.IsDone()) {
                // there should be only one value as the final result
                StackFrame top = this.callstack.Top();
                return top.evaluated[0];
            }
            this.EvalStep();
        }
    }

    // evaluate an expression by putting it on the call stack and calling
    // Eval().
    LispObject EvalExpr(LispObject expr, LispEnvironment env) {
        this.callstack.Push(new StackFrame(expr, env));
        LispObject result = this.Eval();
        this.callstack.Clear();
        return result;
    }

    LispObject[] EvalString(dstring s) {
        LispObject[] results = [];
        auto reader = new StringReader(s);
        while (true) {
            try {
                LispObject expr = reader.Read();
                LispObject result = this.EvalExpr(expr, this.global_env);
                results ~= result;
            } catch (NoInputException e) {
                break;
            }
        }
        return results;
    }

    void MainLoop() {
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
            }
            //writeln(expr.Repr());
            LispObject result = this.EvalExpr(expr, this.global_env);
            writefln("%s", result.Repr());
        }
    }
}

