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
