// b_string.d

import std.algorithm.searching : startsWith, endsWith;
import errors;
import interpreter;
import tools;
import types;

// (STRING->SYMBOL str) => symbol
LispObject b_string_to_symbol(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto s = cast(LispString) fargs.args[0]) {
        return LispSymbol.Get(s.value);
    } else
        throw new XTypeError("STRING->SYMBOL", "string", fargs.args[0]);
}

LispObject b_string_starts_with(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto s = cast(LispString) fargs.args[0]) {
        if (auto prefix = cast(LispString) fargs.args[1]) {
            return startsWith(s.value, prefix.value) ? TRUE() : FALSE();
        } else
            throw new XTypeError("STRING-STARTS-WITH?", "string", fargs.args[1]);
    } else
        throw new XTypeError("STRING-STARTS-WITH?", "string", fargs.args[0]);
}

