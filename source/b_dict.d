// b_dict.d
// Built-in dictionary functions.

import errors;
import interpreter;
import types;

// (DICT_GET <dict> key [default])
LispObject b_dict_get(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto d = cast(LispDictionary) fargs.args[0]) {
        LispObject key = fargs.args[1];
        if (fargs.rest_args.length > 0) {
            return d.GetDefault(key, fargs.rest_args[0]);
        } else {
            return d.Get(key);
        }
    } else throw new TypeError("dictionary expected");
}


