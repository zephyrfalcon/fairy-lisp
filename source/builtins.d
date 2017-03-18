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

struct FI {
    BuiltinFunctionSig f;
    int arity;
}
FI[dstring] GetBuiltins() {
    FI[dstring] builtins = [
        "+": FI(&b_plus, 0),
    ];
    return builtins;
}

