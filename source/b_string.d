// b_string.d

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


