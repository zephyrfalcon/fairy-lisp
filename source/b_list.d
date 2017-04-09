// b_list.d
// Built-in functions for lists.

import errors;
import interpreter;
import types;

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

LispObject b_reverse(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto list = cast(LispList) fargs.args[0]) {
        auto rev = list.Reverse();
        return rev;
    } else
        throw new TypeError("list expected");
}

