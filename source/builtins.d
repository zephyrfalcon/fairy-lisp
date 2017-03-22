// builtins.d
// Built-in functions.

import std.format;
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

LispObject b_cons(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return new LispPair(fargs.args[0], fargs.args[1]);
}

LispObject b_car(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto p = cast(LispPair) fargs.args[0]) {
        return p.head;
    } else
        throw new TypeError("CAR: argument must be a list");
}

LispObject b_cdr(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto p = cast(LispPair) fargs.args[0]) {
        return p.tail;
    } else
        throw new TypeError("CDR: argument must be a list");
}


struct FI {
    BuiltinFunctionSig f;
    int arity;
}
FI[dstring] GetBuiltins() {
    FI[dstring] builtins = [
        "+": FI(&b_plus, 0),
        "car": FI(&b_car, 1),
        "cdr": FI(&b_cdr, 1),
        "cons": FI(&b_cons, 2),
    ];
    return builtins;
}

