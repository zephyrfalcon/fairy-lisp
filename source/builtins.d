// builtins.d
// Built-in functions.

import std.conv;
import std.file;
import std.format;
import std.stdio;
import errors;
import interpreter;
import stackframe;
import reader;
import tools;
import types;


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
        return LispSymbol.Get(t.name);
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

LispObject b_gensym(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return LispSymbol.GenUnique();
}

// (ERROR msg)
LispObject b_error(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto msg = cast(LispString) fargs.args[0]) {
        throw new Exception(to!string(msg.value));
    } else
        throw new XTypeError("ERROR", "string", fargs.args[0]);
}

// (READ-FILE-AS-STRING filename)
// XXX can be written in pure Lisp later, once we have files and a way to read
// their contents as one big string
LispObject b_read_file_as_string(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto filename = cast(LispString) fargs.args[0]) {
        string stuff = readText(filename.value);
        dstring all = to!dstring(stuff);
        return new LispString(all);
    } else
        throw new XTypeError("READ-FILE-AS-STRING", "string", fargs.args[0]);
}


/*** EVAL-STRING ***/

// Expressions in the string are evaluated in a given environment, or, if such
// an environment is not specified, the current environment.
//
// This is done by creating a new expression (EVAL (QUOTE <expr>) <env>),
// using the EVAL procedure defined in the prelude.
//
// Since we need to refer to the environment (in which the expressions must be
// evaluated) *by name*, we create a *temporary environment* based on the
// current environment, which contains such a name. (This name is generated
// much like GENSYM, and should be unique.) The (EVAL ..) expression mentioned
// above is then evaluated in this temporary environment.
//
// NOTE: The original expression passed to EVAL should be evaluated in the
// environment specified, but the expression (EVAL ..) *itself* should be
// evaluated in the current environment! Otherwise, code like
//   (EVAL-STRING "(+ 1 2)" (BUILTIN-ENV))
// ...would not work, even though the expression (+ 1 2) should evaluate just
// find in the builtin environment.

class EvalStringHelper : StackFrameHelper {
    StringReader reader;
    LispObject[] results;
    LispEnvironment env;
    LispEnvironment temp_env;
    dstring env_name;
    this(StringReader reader, LispEnvironment env) {
        this.reader = reader;
        this.env = env;
        this.results = [];
    }
    override void Receive(LispObject x) {
        this.results ~= x;
    }
}

// (EVAL-STRING string [env])
// XXX can be written in pure Lisp once we have a string reader
LispObject b_eval_string(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto s = cast(LispString) fargs.args[0]) {
        auto top = intp.callstack.Top();
        if (top.aux_data is null) {
            auto reader = new StringReader(s.value);
            LispEnvironment thisenv;
            if (fargs.rest_args.length > 0) {
                if (auto eenv = cast(LispEnvironment) fargs.rest_args[0]) {
                    thisenv = eenv;
                } else
                    throw new XTypeError("EVAL-STRING", "environment",
                                         fargs.rest_args[0]);
            } else {
                thisenv = env;
            }
            auto aux = new EvalStringHelper(reader, thisenv);
            // create a new temporary environment, containing a (gensym'ed)
            // name that refers to the environment we want to evaluate the
            // expressions in. 
            aux.temp_env = new LispEnvironment(env);  // not thisenv
            aux.env_name = LispSymbol.GenUnique().value;
            aux.temp_env.Set(aux.env_name, thisenv);
            top.aux_data = aux;
        }

        if (auto aux = cast(EvalStringHelper) top.aux_data) {
            // check reader for next expression
            LispObject expr;
            try {
                expr = aux.reader.Read();
            } catch (NoInputException e) {
                // end of expressions reached
                if (aux.results.length > 0)
                    return aux.results[$-1];
                else 
                    return FALSE();
            }

            // transform into: (EVAL <expr> (CURRENT-ENV))
            // (because macroexpansion etc is already done by EVAL in prelude!)
            auto quoted_expr = new LispPair(LispSymbol.Get("quote"), new
                    LispPair(expr, NIL()));
            auto newexpr = new LispPair(LispSymbol.Get("eval"),
                           new LispPair(quoted_expr, 
                           new LispPair(LispSymbol.Get(aux.env_name), 
                               NIL())));

            //writeln("#DEBUG: to be evaluated: ", newexpr.Repr());

            // and evaluate that via stack!
            auto sf = new StackFrame(newexpr, aux.temp_env);
            intp.callstack.Push(sf);
            return null;
        } else
            throw new TypeError("invalid auxiliary data");
    } else
        throw new XTypeError("EVAL-STRING", "string", fargs.args[0]);
}

struct FI {
    BuiltinFunctionSig f;
    int arity;
}
FI[dstring] GetBuiltins() {
    import b_arith, b_dict, b_env;
    import b_list, b_module, b_path, b_string;

    FI[dstring] builtins = [
        "addr": FI(&b_addr, 1),
        "apply": FI(&b_apply, 2),
        "eq?": FI(&b_eq, 2),
        "equal?": FI(&b_equal, 2),
        "error": FI(&b_error, 1),
        "eval-raw": FI(&b_eval_raw, 1),
        "eval-string": FI(&b_eval_string, 1),
        "function-args": FI(&b_function_args, 1),
        "function-body": FI(&b_function_body, 1),
        "gensym": FI(&b_gensym, 0),
        "print": FI(&b_print, 0),
        "read-file-as-string": FI(&b_read_file_as_string, 1),
        "set-debug-option": FI(&b_set_debug_option, 2),
        "type": FI(&b_type, 1),
        "type-name": FI(&b_type_name, 1),
        "type-parent": FI(&b_type_parent, 1),

        /* b_arith.d */
        "+": FI(&b_plus, 0),
        "=": FI(&b_equals, 2),
        "<": FI(&b_less_than, 2),
        ">": FI(&b_greater_than, 2),

        /* b_dict.d */
        "dict-get": FI(&b_dict_get, 2),
        "make-dict": FI(&b_make_dict, 0),

        /* b_env.d */
        "builtin-env": FI(&b_builtin_env, 0),
        "current-env": FI(&b_current_env, 0),
        "env-get": FI(&b_env_get, 2),
        "env-has?": FI(&b_env_has, 2),
        "env-local-names": FI(&b_env_local_names, 1),
        "env-names": FI(&b_env_names, 1),
        "env-set!": FI(&b_env_set, 3),
        "global-env": FI(&b_global_env, 0),
        "make-env": FI(&b_make_env, 0),

        /* b_list.d */
        "append": FI(&b_append, 2),
        "car": FI(&b_car, 1),
        "cdr": FI(&b_cdr, 1),
        "cons": FI(&b_cons, 2),
        "length": FI(&b_length, 1),
        "reverse": FI(&b_reverse, 1),

        /* b_module.d */
        "make-module": FI(&b_make_module, 1),
        "module-env": FI(&b_module_env, 1),

        /* b_path.d */
        "absolute-path": FI(&b_absolute_path, 1),
        "get-dir-part": FI(&b_get_dir_part, 1),
        "get-executable": FI(&b_get_executable, 0),
        "get-file-base-name": FI(&b_get_file_base_name, 1),
        "get-file-part": FI(&b_get_file_part, 1),
        "path-join": FI(&b_path_join, 1),

        /* b_string.d */
        "%%string-join": FI(&b_xx_string_join, 1),
        "->string": FI(&b_to_string, 1),
        "string->symbol": FI(&b_string_to_symbol, 1),
        "string-contains?": FI(&b_string_contains, 2),
        "string-ends-with?": FI(&b_string_ends_with, 2),
        "string-split": FI(&b_string_split, 1),
        "string-starts-with?": FI(&b_string_starts_with, 2),
    ];
    return builtins;
}

