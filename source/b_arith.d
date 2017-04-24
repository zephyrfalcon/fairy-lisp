// b_arith.d

import std.format;
import std.stdio;
import errors;
import interpreter;
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

LispObject b_equals(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto n1 = cast(LispInteger) fargs.args[0]) {
        if (auto n2 = cast(LispInteger) fargs.args[1]) {
            return (n1.value == n2.value) ? TRUE() : FALSE();
        } else
            throw new TypeError("number expected");
    } else
        throw new TypeError("number expected");
}

