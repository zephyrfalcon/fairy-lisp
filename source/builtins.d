// builtins.d
// Built-in functions.

import std.format;
import std.stdio;
import errors;
import interpreter;
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

// (ENV-GET env name [default])
LispObject b_env_get(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto this_env = cast(LispEnvironment) fargs.args[0]) {
        if (auto name = cast(LispSymbol) fargs.args[1]) {
            try {
                LispObject result = this_env.Get(name.value);
                return result;
            } catch (EnvironmentKeyException e) {
                if (fargs.rest_args.length > 0) 
                    return fargs.rest_args[0];
                throw e;
            }
        } else
            throw new TypeError("ENV-GET: name must be a symbol");
    } else 
        throw new TypeError("ENV-GET: first argument must be an environment");
}

// return the current environment
LispObject b_current_env(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return env;
}

// create a new FunctionArgs object to be used by APPLY.
// this should take into account:
// - the arity of the function being called (which determines which arguments
// are "regular", vs which ones are rest arguments
// - keywords (passed as a keyword dict, the way we get in %keywords)
FunctionArgs MakeApplyFunctionArgs(LispFunction callable, LispObject[] args, LispDictionary d)
{
    auto fa = FunctionArgs.Parse(callable.arity, args);
    if (d !is null)
        fa.keyword_args = d.ToHashmap();
    // NOTE: any keyword args we specify in `args` will be overwritten!
    return fa;
}

// (APPLY f args [keywords])
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

struct FI {
    BuiltinFunctionSig f;
    int arity;
}
FI[dstring] GetBuiltins() {
    import b_dict;
    import b_list;
    FI[dstring] builtins = [
        "+": FI(&b_plus, 0),
        "addr": FI(&b_addr, 1),
        "apply": FI(&b_apply, 2),
        "current-env": FI(&b_current_env, 0),
        "env-get": FI(&b_env_get, 2),
        "eq?": FI(&b_eq, 2),
        "equal?": FI(&b_equal, 2),
        "print": FI(&b_print, 0),
        "type": FI(&b_type, 1),
        "type-name": FI(&b_type_name, 1),
        "type-parent": FI(&b_type_parent, 1),

        /* b_dict.d */
        "dict-get": FI(&b_dict_get, 2),
        "make-dict": FI(&b_make_dict, 0),

        /* b_list.d */
        "append": FI(&b_append, 2),
        "car": FI(&b_car, 1),
        "cdr": FI(&b_cdr, 1),
        "cons": FI(&b_cons, 2),
        "reverse": FI(&b_reverse, 1),
    ];
    return builtins;
}

