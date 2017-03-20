// interpreter.d

import std.array;
import std.conv;
import std.format;
import std.stdio;

import builtins;
import callstack;
import errors;
import reader;
import special;
import stackframe;
import tools;
import types;

class Interpreter {
    dstring prompt = "> ";
    CallStack callstack;
    LispEnvironment builtin_env;
    LispEnvironment global_env;
    // TODO: debug options

    SpecialFormSig[dstring] special_forms;

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

        // load special forms
        this.special_forms = GetSpecialForms();

        // load builtin functions
        FI[dstring] builtins = GetBuiltins();
        foreach (name; builtins.keys) {
            FI fi = builtins[name];
            auto bf = new LispBuiltinFunction(name, fi.f, fi.arity);
            this.builtin_env.Set(name, bf);
        }
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
                if (auto f = cast(LispFunction) top.evaluated[0]) {
                    auto args = top.evaluated[1..$]; // may be empty
                    auto fargs = FunctionArgs.Parse(f.arity, args);
                    auto result = this.CallFunction(top.env, f, fargs);
                    if (result !is null)
                        this.callstack.Collapse(result);
                } else throw new Exception("first element of function call must be callable");
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

            // is it a special form?
            if (auto sym = cast(LispSymbol) top.to_be_evaluated[0]) {
                SpecialFormSig *p = (sym.value in this.special_forms);
                if (p !is null) {
                    LispObject result = (*p)(this, top.env, top.to_be_evaluated);
                    if (result !is null)
                        this.callstack.Collapse(result);
                    return;
                }                 
            }

            // evaluate the next element of the compound form by putting it on
            // the call stack
            auto elem = top.to_be_evaluated[0];
            top.to_be_evaluated = top.to_be_evaluated[1..$];
            auto sf = new StackFrame(elem, top.env);
            this.callstack.Push(sf);

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

    LispObject CallFunction(LispEnvironment caller_env, LispFunction callable,
                            FunctionArgs fargs) {
        if (auto bf = cast(LispBuiltinFunction) callable) {
            LispObject result = bf.f(this, caller_env, fargs);
            return result;
        } else if (auto uf = cast(LispUserDefinedFunction) callable) {
            // make sure the number of arguments matches
            if (fargs.args.length != uf.argnames.length)
                throw new Exception(
                        format("incorrect number of arguments; expected %d, got %d", 
                            uf.argnames.length, fargs.args.length));
            // create new environment based on the lambda's environment
            auto newenv = new LispEnvironment(uf.env);
            // add new values to it
            foreach(i, name; uf.argnames) {
                newenv.Set(name, fargs.args[i]);
            }
            // create %rest, %keywords variables in new env
            newenv.Set("%rest", LispList.FromArray(fargs.rest_args));
            // TODO: newenv.Set("keywords", new LispDictionary(fargs.keyword_args));
            LispObject fbody = WrapExprsInDo(uf.fbody);
            auto sf = new StackFrame(fbody, newenv);
            this.callstack.Pop();  // pop frame containing function call (TCO)
            this.callstack.Push(sf);
            return null;  // evaluate via stack as usual
        } else throw new Exception("not a callable");  // should not happen
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

