// b_dict.d
// Built-in dictionary functions.

import std.stdio;
import errors;
import interpreter;
import types;

// (DICT-GET <dict> key [default])
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

// (MAKE-DICT k1 v1 k2 v2 ...)
LispObject b_make_dict(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    auto d = new LispDictionary();
    for (ulong i=0; i < fargs.rest_args.length; i++) {
        if (i == fargs.rest_args.length - 1)
            throw new Exception("not enough arguments");
        auto key = fargs.rest_args[i];
        auto value = fargs.rest_args[i+1];
        d.Set(key, value);
        i++;
    }
    return d;
}

