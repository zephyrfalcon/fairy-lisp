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
        "car": FI(&b_car, 1),
        "cdr": FI(&b_cdr, 1),
        "cons": FI(&b_cons, 2),
        "reverse": FI(&b_reverse, 1),
    ];
    return builtins;
}

