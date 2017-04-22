// builtins.d
// Built-in functions.

import std.format;
import std.stdio;
import errors;
import interpreter;
import stackframe;
import tools;
import types;

LispObject b_plus(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    int result = 0;
    auto all_args = fargs.GetAllArgs();
    foreach(arg; all_args) {
        if (auto li = cast(LispInteger) arg) {
            result += li.value;
        } else throw new TypeError(format("number expected; got %s instead (%s)",
                    "{something else}", arg.Repr()));
    }
    return new LispInteger(result);
}

LispObject b_eq(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    auto p1 = cast(void *) fargs.args[0];
    auto p2 = cast(void *) fargs.args[1];
    return (p1 == p2) ? TRUE() : FALSE();
}

LispObject b_addr(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    auto p = cast(void *) fargs.args[0];
    return new LispInteger(cast(int) p);
}

// (TYPE-NAME <type>)
LispObject b_type_name(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto t = cast(LispType) fargs.args[0]) {
        return new LispSymbol(t.name);
    } else throw new TypeError("TYPE-NAME: type object expected");
}

// (TYPE x)
LispObject b_type(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return fargs.args[0].GetType();
}

// (TYPE-PARENT <type>)
LispObject b_type_parent(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto t = cast(LispType) fargs.args[0]) {
        return t.parent;
    } else throw new TypeError("TYPE-NAME: type object expected");
}

// crude way to implement equality. XXX temporary solution
// chances are that EQUAL? will be a multimethod someday. in any case,
// comparing objects will likely be more complicated than this.
LispObject b_equal(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    auto a = fargs.args[0];
    auto b = fargs.args[1];
    return a == b ? TRUE() : FALSE();
}

LispObject b_print(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    LispObject last = FALSE();
    foreach(obj; fargs.args ~ fargs.rest_args) {
        if (auto s = cast(LispString) obj) {
            write(s.value);
        } else {
            write(obj.Repr());
        }
        last = obj;
    }
    return last;
}


// create a new FunctionArgs object to be used by APPLY.
// this should take into account:
// - the arity of the function being called (which determines which arguments
// are "regular", vs which ones are rest arguments
// - keywords (passed as a keyword dict, the way we get in %keywords)
FunctionArgs MakeApplyFunctionArgs(LispFunction callable, LispObject[] args, LispDictionary d)
{
    auto fa = FunctionArgs.Parse(callable.arity, args, []);
    if (d !is null)
        fa.keyword_args = d.ToHashmap();
    // NOTE: any keyword args we specify in `args` will be overwritten!
    // figure out later if this is desirable...
    return fa;
}

// (APPLY f args [keywords])
// Apply the given arguments to function f. The arguments will be considered
// regular arguments or rest arguments if there are more of them than the
// function's arity; any keywords in the argument list are considered regular
// arguments as well, rather than keyword arguments. In order to pass keyword
// arguments, use the third parameter (a keyword dictionary).
//
// So this:  (apply f '(f 1 :foo 2))
// has ZERO keyword arguments; rather, it has three regular arguments 1, :foo
// and 2.
LispObject b_apply(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto f = cast(LispFunction) fargs.args[0]) {
        if (auto lst = cast(LispList) fargs.args[1]) {
            // prepare FunctionArgs object
            LispObject[] myargs = lst.ToArray();
            FunctionArgs fa;
            if (fargs.rest_args.length > 0) {
                if (auto kwargs = cast(LispDictionary) fargs.rest_args[0]) {
                    fa = MakeApplyFunctionArgs(f, myargs, kwargs);
                } else
                    throw new TypeError("APPLY: keyword argument must be"
                                      ~ "passed as a dictionary");
            } else
                fa = MakeApplyFunctionArgs(f, myargs, null);
            return intp.CallFunction(env, f, fa);
        } else
            throw new TypeError("APPLY: arguments must be a list");
    } else
        throw new TypeError("APPLY: first argument must be a callable");
}

LispObject b_function_args(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto f = cast(LispUserDefinedFunction) fargs.args[0]) {
        LispObject[] names = NamesAsSymbols(f.argnames);
        return LispList.FromArray(names);
    } else
        throw new TypeError("argument must be a (non-builtin) function");
}

LispObject b_function_body(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto f = cast(LispUserDefinedFunction) fargs.args[0]) {
        return LispList.FromArray(f.fbody);
    } else
        throw new TypeError("argument must be a (non-builtin) function");
}

// (SET-DEBUG-OPTION name value)
// a work in progress. for now, only supports 'show-call-stack'.
LispObject b_set_debug_option(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto name = cast(LispSymbol) fargs.args[0]) {
        if (name.value == "show-call-stack") {
            bool value = (fargs.args[1] is FALSE()) ? false : true;
            intp.debug_options.show_call_stack = value;
            return TRUE();
        } else throw new Exception(format("unknown option name: %s", name.value));
    } else
        throw new TypeError("first argument must be a symbol");
}

// (EVAL-RAW expr [env])
// Evaluates the given expression in the given environment (or the current
// environment). Does NOT expand macros.
LispObject b_eval_raw(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    LispObject expr = fargs.args[0];
    LispEnvironment eval_env = env;
    if (fargs.rest_args.length > 0) {
        if (auto opt_env = cast(LispEnvironment) fargs.rest_args[0]) {
            eval_env = opt_env;
        } else 
            throw new TypeError("EVAL: second argument must be environment");
    }
    // put expr and env on the stack
    StackFrame sf = new StackFrame(expr, eval_env);
    intp.callstack.Pop();  // TCO
    intp.callstack.Push(sf);
    return null;
}

struct FI {
    BuiltinFunctionSig f;
    int arity;
}
FI[dstring] GetBuiltins() {
    import b_dict, b_env;
    import b_list;
    FI[dstring] builtins = [
        "+": FI(&b_plus, 0),
        "addr": FI(&b_addr, 1),
        "apply": FI(&b_apply, 2),
        "eq?": FI(&b_eq, 2),
        "equal?": FI(&b_equal, 2),
        "eval-raw": FI(&b_eval_raw, 1),
        "function-args": FI(&b_function_args, 1),
        "function-body": FI(&b_function_body, 1),
        "print": FI(&b_print, 0),
        "set-debug-option": FI(&b_set_debug_option, 2),
        "type": FI(&b_type, 1),
        "type-name": FI(&b_type_name, 1),
        "type-parent": FI(&b_type_parent, 1),

        /* b_dict.d */
        "dict-get": FI(&b_dict_get, 2),
        "make-dict": FI(&b_make_dict, 0),

        /* b_env.d */
        "builtin-env": FI(&b_builtin_env, 0),
        "current-env": FI(&b_current_env, 0),
        "env-get": FI(&b_env_get, 2),
        "env-has?": FI(&b_env_has, 2),
        "global-env": FI(&b_global_env, 0),

        /* b_list.d */
        "append": FI(&b_append, 2),
        "car": FI(&b_car, 1),
        "cdr": FI(&b_cdr, 1),
        "cons": FI(&b_cons, 2),
        "reverse": FI(&b_reverse, 1),
    ];
    return builtins;
}

