// b_string.d

import std.algorithm.searching : startsWith, endsWith, count;
import std.array : join, split;
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

LispObject b_string_ends_with(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto s = cast(LispString) fargs.args[0]) {
        if (auto prefix = cast(LispString) fargs.args[1]) {
            return endsWith(s.value, prefix.value) ? TRUE() : FALSE();
        } else
            throw new XTypeError("STRING-STARTS-WITH?", "string", fargs.args[1]);
    } else
        throw new XTypeError("STRING-STARTS-WITH?", "string", fargs.args[0]);
}

// (->STRING x)
// May be renamed later to STRING? Also would become a multimethod? But for
// now, it's a built-in.
LispObject b_to_string(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return new LispString(fargs.args[0].ToString());
}

// (%%STRING-JOIN <list-of-strings> [sep])
// Joins a list of strings. All elements of the list MUST be strings. (A more
// forgiving version will be written in pure Lisp.)
LispObject b_xx_string_join(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto strs = cast(LispList) fargs.args[0]) {
        LispObject[] xs = strs.ToArray();
        dstring[] parts = [];
        foreach(x; xs) {
            if (auto s = cast(LispString) x) {
                parts ~= s.value;
            } else
                throw new XTypeError("%%STRING-JOIN", "string", x);
        }
        // do we have a separator?
        dstring sep = "";
        if (fargs.rest_args.length > 0) {
            if (auto xsep = cast(LispString) fargs.rest_args[0]) {
                sep = xsep.value;
            } else
                throw new XTypeError("%%STRING-JOIN", "string", fargs.rest_args[0]);
        }
        // construct the new string
        dstring result = join(parts, sep);
        return new LispString(result);
    } else
        throw new XTypeError("%%STRING-JOIN", "list", fargs.args[0]);
}

// (STRING-SPLIT s [sep])
// Split a string on whitespace. If a separator is given, split on that.
// Return a list of the parts; the separators are not included.
LispObject b_string_split(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto s = cast(LispString) fargs.args[0]) {
        // do we have a separator?
        dstring sep = "";
        if (fargs.rest_args.length > 0) {
            if (auto xsep = cast(LispString) fargs.rest_args[0]) {
                sep = xsep.value;
            } else
                throw new XTypeError("STRING-SPLIT", "string", fargs.rest_args[0]);
        }
        // split the string
        dstring[] parts = (sep == "") ? split(s.value) : split(s.value, sep);
        // construct a result list
        LispObject[] xparts = [];
        foreach(part; parts) 
            xparts ~= new LispString(part);
        return LispList.FromArray(xparts);
    } else
        throw new XTypeError("STRING-SPLIT", "string", fargs.args[0]);
}

// (STRING-CONTAINS? s substr)
// (later: we could accept a char as the second argument as well...)
LispObject b_string_contains(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto s = cast(LispString) fargs.args[0]) {
        if (auto substr = cast(LispString) fargs.args[1]) {
            auto numocc = count(s.value, substr.value);
            return numocc > 0 ? TRUE() : FALSE();
        } else
            throw new XTypeError("STRING-CONTAINS?", "string", fargs.args[1]);
    } else
        throw new XTypeError("STRING-CONTAINS?", "string", fargs.args[0]);
}

