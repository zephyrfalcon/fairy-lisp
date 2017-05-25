// b_arith.d

import std.format;
import std.stdio;
import errors;
import interpreter;
import tools;
import types;

/*** binary operation helpers ***/

alias IntOpSig = int function(int, int);
alias RealOpSig = real function(real, real);


LispNumber binop(LispNumber a, LispNumber b, IntOpSig intop, RealOpSig realop) {
    if (auto ia = cast(LispInteger) a) {
        if (auto ib = cast(LispInteger) b) {
            // integer addition
            return new LispInteger(intop(ia.value, ib.value));
        }
    }
    return new LispFloat(realop(a.AsFloat(), b.AsFloat()));
}

LispObject _binop_template(Interpreter intp, LispEnvironment env, FunctionArgs
    fargs, dstring name, IntOpSig intop, RealOpSig realop) 
{
    if (auto a = cast(LispNumber) fargs.args[0]) {
        if (auto b = cast(LispNumber) fargs.args[1]) {
            return binop(a, b, intop, realop);
        } else
            throw new XTypeError(name, "number", fargs.args[1]);
    } else
        throw new XTypeError(name, "number", fargs.args[0]);
}

/*** binary operation core functions ***/

LispObject b_xx_plus(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return _binop_template(intp, env, fargs, "%%+", 
            function(int x, int y) { return x + y; },
            function(real x, real y) { return x + y; });
}

LispObject b_xx_minus(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return _binop_template(intp, env, fargs, "%%-", 
            function(int x, int y) { return x - y; },
            function(real x, real y) { return x - y; });
}

LispObject b_xx_times(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return _binop_template(intp, env, fargs, "%%*", 
            function(int x, int y) { return x * y; },
            function(real x, real y) { return x * y; });
}

/*** current, un-generalized functions ***/

// NOTE: built-in + has been replaced with Lisp +, which uses built-in %%+.
/*
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
*/

// similar templates, but for comparing two numbers:

alias CompIntOpSig = bool function(int, int);
alias CompRealOpSig = bool function(real, real);

LispBoolean cbinop(LispNumber a, LispNumber b, CompIntOpSig intop, CompRealOpSig realop) {
    if (auto ia = cast(LispInteger) a) {
        if (auto ib = cast(LispInteger) b) {
            // integer addition
            return intop(ia.value, ib.value) ? TRUE() : FALSE();
        }
    }
    return realop(a.AsFloat(), b.AsFloat()) ? TRUE() : FALSE();
}

LispObject _cbinop_template(Interpreter intp, LispEnvironment env, FunctionArgs
    fargs, dstring name, CompIntOpSig intop, CompRealOpSig realop) 
{
    if (auto a = cast(LispNumber) fargs.args[0]) {
        if (auto b = cast(LispNumber) fargs.args[1]) {
            return cbinop(a, b, intop, realop);
        } else
            throw new XTypeError(name, "number", fargs.args[1]);
    } else
        throw new XTypeError(name, "number", fargs.args[0]);
}

LispObject b_equals(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    return _cbinop_template(intp, env, fargs, "=", 
            function(int x, int y) { return x == y; },
            function(real x, real y) { return x == y; });
}

// OLD
LispObject __b_equals(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto n1 = cast(LispInteger) fargs.args[0]) {
        if (auto n2 = cast(LispInteger) fargs.args[1]) {
            return (n1.value == n2.value) ? TRUE() : FALSE();
        } else
            throw new TypeError("number expected");
    } else
        throw new TypeError("number expected");
}

// FIXME
LispObject b_less_than(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto n1 = cast(LispInteger) fargs.args[0]) {
        if (auto n2 = cast(LispInteger) fargs.args[1]) {
            return (n1.value < n2.value) ? TRUE() : FALSE();
        } else
            throw new TypeError("number expected");
    } else
        throw new TypeError("number expected");
}

// FIXME
LispObject b_greater_than(Interpreter intp, LispEnvironment env, FunctionArgs fargs) {
    if (auto n1 = cast(LispInteger) fargs.args[0]) {
        if (auto n2 = cast(LispInteger) fargs.args[1]) {
            return (n1.value > n2.value) ? TRUE() : FALSE();
        } else
            throw new TypeError("number expected");
    } else
        throw new TypeError("number expected");
}

