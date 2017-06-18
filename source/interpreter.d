// interpreter.d

import std.array;
import std.conv;
import std.file;
import std.format;
import std.path;
import std.stdio;

import builtins;
import callstack;
import errors;
import reader;
import special;
import stackframe;
import tools;
import types;

struct DebugOptions {
    bool show_call_stack = false;
}

class Interpreter {
    CallStack callstack;
    LispEnvironment builtin_env;
    LispEnvironment global_env;
    DebugOptions debug_options;

    SpecialFormSig[dstring] special_forms;

    this() {
        this.debug_options = DebugOptions();
        this.callstack = new CallStack();
        this.builtin_env = new LispEnvironment();
        this.global_env = new LispEnvironment(this.builtin_env);
        this.LoadBuiltins();
        this.AutoLoadCode();
    }

    void LoadBuiltins() {
        this.builtin_env.Set("true", TRUE());
        this.builtin_env.Set("false", FALSE());
        this.builtin_env.Set("*macroexpand-hook*", FALSE());

        // load special forms
        this.special_forms = GetSpecialForms();

        // load type objects
        this.LoadTypes();

        // load builtin functions
        FI[dstring] builtins = GetBuiltins();
        foreach (name; builtins.keys) {
            FI fi = builtins[name];
            auto bf = new LispBuiltinFunction(name, fi.f, fi.arity);
            this.builtin_env.Set(name, bf);
        }
    }

    void LoadTypes() {
        dstring[][] typespecs = [
            ["type"],
            ["number", "type"],
            ["integer", "number"],
            ["float", "number"],
            ["string", "type"],
            ["symbol", "type"],
            ["char", "type"],
            ["list", "type"],
            ["nil", "list"],
            ["pair", "list"],
            ["function", "type"],
            ["bfunc", "function"],
            ["ufunc", "function"],
            ["dict", "type"],
            ["env", "type"],
            ["boolean", "type"],
            ["keyword", "type"],
            ["macro", "ufunc"],
            ["module", "type"],
            ["vector", "type"],
        ];
        foreach(dstring[] spec; typespecs) {
            if (spec.length == 1) {
                dstring name = spec[0];
                LispType t = new LispType(name);
                LispObject._types[name] = t;
                this.builtin_env.Set(format("<%s>"d, name), t);
            } else {
                dstring name = spec[0];
                dstring parent_name = spec[1];
                LispType parent = LispObject._types[parent_name];
                LispType t = new LispType(name, parent);
                LispObject._types[name] = t;
                this.builtin_env.Set(format("<%s>"d, name), t);
            }
        }
        // type is its own parent
        auto type_root = LispObject._types["type"];
        type_root.parent = type_root;
    }

    void AutoLoadCode() {
        auto path = buildPath(WhereAmI(), "source", "load", "autoload.fl");
        this.RunFile(path, this.builtin_env);
    }

    // maybe specify custom env?
    void RunFile(string filename, LispEnvironment env = null) {
        if (env is null)
            env = this.global_env;
        string stuff = readText(filename);
        dstring all = to!dstring(stuff);
        this.EvalString(all, env);
    }

    LispObject EvalAtomic(LispObject expr, LispEnvironment env) {
        // symbols are looked up
        if (auto sym = cast(LispSymbol) expr) {
            // FIXME: this should really be resolved in the parser/reader
            if (sym.value == ".")
                throw new Exception("invalid use of '.'");
            LispObject value = env.Get(sym.value);
            return value;
        } else {
            // everything else evaluates to itself
            return expr;
        }
    }

    void EvalStep() {
        StackFrame top = this.callstack.Top();
        
        //if (!top.IsDone() && IsImproperList(top.original_expr))
        //    throw new SyntaxError(format("cannot evaluate improper list: %s",
        //                          top.original_expr.Repr()));

        if (top.IsDone()) {
            if (top.is_atomic) {
                LispObject value = top.evaluated[0];
                this.callstack.Collapse(value);
            } else {
                // if we're done evaluating all the parts, we can call the
                // function.
                if (auto f = cast(LispFunction) top.evaluated[0]) {
                    if (cast(LispMacro) f) {
                        throw new TypeError("macros cannot be called as functions!");
                    }
                    auto args = top.evaluated[1..$]; // may be empty
                    auto fargs = FunctionArgs.Parse(f.arity, args,
                                 top.keyword_literals);
                    auto result = this.CallFunction(top.env, f, fargs);
                    if (result !is null)
                        this.callstack.Collapse(result);
                } else 
                    throw new Exception(
                            format("callable expected; got %s instead (%s)",
                                top.evaluated[0].Repr(),
                                top.evaluated[0].GetType().name));
            }
            return;
        } 

        if (top.is_atomic) {
            assert(top.evaluated.length == 0, "this is not supposed to happen");
            LispObject result = this.EvalAtomic(top.original_expr, top.env);
            if (top.aux_data !is null) {
                top.aux_data.Receive(result);
            } else {
                top.evaluated ~= result;
            }
        } else {
            // it's a compound expression

            // is it a special form? we check for this in two cases:
            // 1) if top.evaluated is empty, or
            // 2) if the stack frame has previously been marked as a special
            // form (this is used for reentrant forms like DEFINE)
            if (top.evaluated.length == 0 || top.is_special) {
                if (auto sym = cast(LispSymbol) top.to_be_evaluated[0]) {
                    SpecialFormSig *p = (sym.value in this.special_forms);
                    if (p !is null) {
                        if (top.evaluated.length == 0)
                            top.is_special = true;
                        LispObject result = (*p)(this, top.env, top.to_be_evaluated);
                        if (result !is null)
                            this.callstack.Collapse(result);
                        return;
                    }                 
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
            if (this.debug_options.show_call_stack)
                this.callstack.Print();
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
        if (IsImproperList(expr))
            throw new SyntaxError(format("cannot evaluate improper list: %s",
                                  expr.Repr()));
        this.callstack.Push(new StackFrame(expr, env));
        LispObject result = this.Eval();
        this.callstack.Clear();
        return result;
    }

    LispObject[] EvalString(dstring s, LispEnvironment env) {
        LispObject[] results = [];
        auto reader = new StringReader(s);
        while (true) {
            try {
                LispObject expr = reader.Read();
                expr = this.MacroExpand(expr, env);
                LispObject result = this.EvalExpr(expr, env);
                results ~= result;
            } catch (NoInputError e) {
                break;
            }
        }
        return results;
    }

    LispObject MacroExpand(LispObject expr, LispEnvironment env) {
        //if (IsImproperList(expr))
        //    throw new SyntaxError(format("cannot evaluate improper list: %s",
        //                          expr.Repr()));
        LispObject hook = this.builtin_env.Get("*macroexpand-hook*");
        if (auto expander = cast(LispFunction) hook) {
            auto newexpr = new LispPair(LispSymbol.Get("*macroexpand-hook*"), 
                                        new LispPair(expr, NIL()));  // bogus
            auto sf = new StackFrame(newexpr, env); 
            sf.to_be_evaluated = [];
            sf.evaluated = [hook, expr, env];
            this.callstack.Push(sf);
            expr = this.Eval();
            // TODO: make this a debug option
            //writeln("after macroexpansion, expr is: ", expr.Repr());
            this.callstack.Clear();
            // XXX there is an issue here when we call EVAL... which
            // should NOT clear the call stack... and which may not play
            // well with the rest of this code either.
        }
        return expr;
    }

    LispObject CallFunction(LispEnvironment caller_env, LispFunction callable,
                            FunctionArgs fargs) {
        if (auto bf = cast(LispBuiltinFunction) callable) {
            if (fargs.args.length < bf.arity) 
                throw new Exception(
                        format("function: %s; incorrect number of arguments; "
                             ~ "expected %d, got %d", 
                               bf.Repr(),
                               bf.arity, fargs.args.length));
            LispObject result = bf.f(this, caller_env, fargs);
            return result;

        } else if (auto uf = cast(LispUserDefinedFunction) callable) {
            // make sure the number of arguments matches
            if (fargs.args.length != uf.argnames.length)
                throw new Exception(
                        format("function: %s; incorrect number of arguments; "
                             ~ "expected %d, got %d", 
                               uf.Repr(),
                               uf.argnames.length, fargs.args.length));
            // create new environment based on the lambda's environment
            auto newenv = new LispEnvironment(uf.env);
            // add new values to it
            foreach(i, name; uf.argnames) 
                newenv.Set(name, fargs.args[i]);
            // create %rest, %keywords variables in new env
            newenv.Set("%rest", LispList.FromArray(fargs.rest_args));
            newenv.Set("%keywords", new LispDictionary(fargs.keyword_args));
            newenv.Set("%caller-env", caller_env);
            LispObject fbody = WrapExprsInDo(uf.fbody);
            auto sf = new StackFrame(fbody, newenv);
            this.callstack.Pop();  // pop frame containing function call (TCO)
            this.callstack.Push(sf);
            return null;  // evaluate via stack as usual

        } else 
            throw new Exception("not a callable");  // should not happen
    }

}

